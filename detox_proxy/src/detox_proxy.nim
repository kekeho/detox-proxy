# Copyright (c) 2020 Hiroki Takemura (kekeho) and Aizack
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT


import asyncdispatch
import asyncnet
import options
import net
import http


var connlist {.threadvar.}: seq[(AsyncSocket, AsyncSocket)]


proc connwatch() {.async.} =
    while true:
        var new_connlist: seq[(AsyncSocket, AsyncSocket)]
        for i, conn in connlist:
            if not (conn[0].isClosed and conn[1].isClosed):
                new_connlist.add(conn)
        connlist = new_connlist

        echo "===== CONNECTIONS ===="
        echo connlist.len
        await sleepAsync(2000)


proc relay(from_socket: AsyncSocket, to_socket: AsyncSocket) {.async.} =
    connlist.add((from_socket, to_socket))
    while true:
        if from_socket.isClosed:
            echo "FROM_SOCKET CLOSED"
            to_socket.close()
            return
        elif to_socket.isClosed:
            echo "TO_SOCKET CLOSED"
            from_socket.close()
            return
        
        try:
            let data = await from_socket.recv(BufferSize)
            if data.len == 0: break
            await to_socket.send(data)
        except OSError:
            echo "OSERROR"
            if not from_socket.isClosed:
                from_socket.close()
            if not to_socket.isClosed:
                to_socket.close()
                

    from_socket.close()
    to_socket.close()
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
        if host.isClosed:
            if not client.isClosed:
                client.close()
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
