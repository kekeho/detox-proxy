import asyncdispatch
import asyncnet
import net


proc relay(from_socket: AsyncSocket, to_socket: AsyncSocket) {.async.} =
    while true:
        let data = await from_socket.recv(BufferSize)
        if data.len == 0: break

        echo "from->to: " & data
        await to_socket.send(data)

    if from_socket.isClosed:
        echo "FROM_SOCKET CLOSED"
        to_socket.close()
    elif to_socket.isClosed:
        echo "TO_SOCKET CLOSED"
        from_socket.close()


proc processClient(client: AsyncSocket) {.async.} =
    let host = newAsyncSocket(buffered=false)
    await host.connect("wa3.i-3-i.info", Port(443))

    echo "CONNECTED"
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


asyncCheck serve()
runForever()

