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
    Connection = ref object
        a: AsyncSocket
        b: AsyncSocket
        timestamp: int64  # unix timestamp
        last_timestamp: int64  # unix timestamp


proc safeClose(a: AsyncSocket, b: AsyncSocket) =
    if not a.isClosed:
        a.close()
    if not b.isClosed:
        b.close()


proc safeClose(conn: Connection) =
    safeClose(conn.a, conn.b)


var connlist {.threadvar.}: seq[Connection]


proc connwatch() {.async.} =
    const interval = 2  # 2s
    const nodata_timelimit = 20 # 20s (from last recv/send)
    const timelimit = 120 # 120s (from connection start)
    while true:
        var new_connlist: seq[Connection]
        let nowUnix = now().toTime.toUnix
        for i, conn in connlist:
            # timestamp check
            if nowUnix - conn.last_timestamp > nodata_timelimit:
                safeClose(conn)
            elif nowUnix - conn.timestamp > timelimit:
                safeClose(conn)
            elif conn.a.isClosed or conn.b.isClosed:
                safeClose(conn)
            else:
                new_connlist.add(conn)

        connlist = new_connlist

        echo "===== CONNECTIONS ===="
        echo connlist.len
        await sleepAsync(interval * 1000)


proc relay(from_socket: AsyncSocket, to_socket: AsyncSocket) {.async.} =
    let conn = Connection(
        a: from_socket, b: to_socket,
        timestamp: now().toTime.toUnix, last_timestamp: 0,
    )
    connlist.add(conn)
    while true:
        if conn.a.isClosed or conn.b.isClosed:
            safeClose(conn)
            return
        
        try:
            let data = await conn.a.recv(BufferSize)
            if data.len == 0:
                safeClose(conn)
                return
            await conn.b.send(data)
            conn.last_timestamp = now().toTime.toUnix
        except OSError:
            safeClose(conn)

    safeClose(conn)
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
