# Copyright (c) 2020 Hiroki Takemura (kekeho) and Aizack
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT


# TODO: File descriptor not registered. [ValueError]がどこかでおきてるので調査する


import asyncdispatch
import asyncnet
import options
import net
import http
import times


type
    Connection = object
        a: AsyncSocket
        b: AsyncSocket
        timestamp: int64  # unix timestamp


proc safeClose(a: AsyncSocket, b: AsyncSocket) =
    if not a.isClosed:
        a.close()
    if not b.isClosed:
        b.close()


var connlist {.threadvar.}: seq[Connection]


proc connwatch() {.async.} =
    const interval = 2  # 2s
    const timelimit = 8 # 8s
    while true:
        var new_connlist: seq[Connection]
        let nowUnix = now().toTime().toUnix()
        for i, conn in connlist:
            # timestamp check
            if nowUnix - conn.timestamp > timelimit:
                echo "Auto close"
                safeClose(conn.a, conn.b)

            if not (conn.a.isClosed and conn.b.isClosed):
                new_connlist.add(conn)
            
        connlist = new_connlist

        echo "===== CONNECTIONS ===="
        echo connlist.len
        await sleepAsync(interval * 1000)


proc relay(from_socket: AsyncSocket, to_socket: AsyncSocket) {.async.} =
    var newConn = Connection(a: from_socket, b: to_socket, timestamp: now().toTime.toUnix)
    connlist.add(newConn)
    while true:
        if from_socket.isClosed or to_socket.isClosed:
            safeClose(from_socket, to_socket)
            return
        
        try:
            let data = await from_socket.recv(BufferSize)
            if data.len == 0:
                safeClose(from_socket, to_socket)
                return
            await to_socket.send(data)
        except OSError:
            echo "OSERROR"
            safeClose(from_socket, to_socket)

    safeClose(from_socket, to_socket)
    echo "CLOSE"


proc processClient(client: AsyncSocket) {.async.} =
    let data = await client.recv(BufferSize)
    if data.len == 0:
        return

    let maybeReq = httpRequestParser(data)
    if maybeReq.isNone():
        echo "failed to parse"
        if not client.isClosed:
            client.close()
        return
    
    let req = maybeReq.get()

    # connect to remote
    let host = newAsyncSocket(buffered=false)

    let maybeHost = req.headers.getHeader("host")
    if maybeHost.isSome:
        await host.connect(maybeHost.get(), req.port)
    echo "CONNECTED " & req.path & ":" & $req.port

    if req.reqMethod == HttpMethod.Connect:
        # return 200 ok to client
        if client.isClosed:
            if not host.isClosed:
                host.close()
            return
        await client.send("HTTP/1.1 200 OK\c\n\c\n")
    else:
        if host.isClosed or client.isClosed:
            safeClose(host, client)
            return
        await host.send(data)

    asyncCheck relay(client, host)
    asyncCheck relay(host, client)


proc serve() {.async.} =
    var server = newAsyncSocket(buffered=false)
    server.setSockOpt(OptReuseAddr, true)
    server.bindAddr(Port(5001))
    server.listen()

    while true:
        let client = await server.accept()
        asyncCheck processClient(client)

when isMainModule:
    asyncCheck serve()
    asyncCheck connwatch()
    runForever()
