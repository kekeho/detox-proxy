# Copyright (c) 2020 Hiroki Takemura (kekeho) and Aizack
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT


import asyncdispatch
import asyncnet
import options
import net
import http

proc relay(from_socket: AsyncSocket, to_socket: AsyncSocket) {.async.} =
    while true:
        let data = await from_socket.recv(BufferSize)
        if data.len == 0: break
        await to_socket.send(data)

    if from_socket.isClosed:
        echo "FROM_SOCKET CLOSED"
        to_socket.close()
    elif to_socket.isClosed:
        echo "TO_SOCKET CLOSED"
        from_socket.close()


proc processClient(client: AsyncSocket) {.async.} =
    let data = await client.recv(BufferSize)
    echo data
    let maybeReq = httpRequestParser(data)
    if maybeReq.isNone():
        echo "failed to parse"
        if not client.isClosed:
            client.close()
        return
    
    let req = maybeReq.get()
    echo req

    # connect to remote
    let host = newAsyncSocket(buffered=false)

    let maybeHost = req.headers.getHeader("host")
    if maybeHost.isSome:
        await host.connect(maybeHost.get(), req.port)
    echo "CONNECTED " & req.path & ":" & $req.port

    if req.reqMethod == HttpMethod.Connect:
        # return 200 ok to client
        await client.send("HTTP/1.1 200 OK\c\n\c\n")
    else:
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
    runForever()
