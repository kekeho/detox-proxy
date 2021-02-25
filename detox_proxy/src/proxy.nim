import asyncnet
import asyncdispatch
import net
import nativesockets
import options

import common


proc processClient(client: AsyncSocket) {.async.} =
    echo "New proxy connection"

    var data: string
    data = await client.recv(1024)

    if data.len == 0:
        echo "LEN"
        return

    let maybeReq = httpRequestParser(data)
    if maybeReq.isNone():
        echo "failed to parse"
        if not client.isClosed:
            client.close()
        return
    
    let req = maybeReq.get()

    # connect to remote
    let maybeHost = req.headers.getHeader("host")
    if maybeHost.isNone:
        if not client.isClosed:
            client.close()
        return

    var hostInfo: Hostent
    try:
        hostInfo = getHostByName(maybeHost.get())  # host check
    except OSError:
        # wrong host/port
        echo "WRONG address/port"
        await client.send("HTTP/1.1 404 Not found\c\n\c\ndetox-proxy: address/port not found\c\n")
        if not client.isClosed:
            client.close()
        return

    var host: AsyncSocket
    try:
        host = newAsyncSocket(buffered=false, domain=hostInfo.addrtype)
        host.setSockOpt(OptReuseAddr, true)
        host.setSockOpt(OptReusePort, true)
        await host.connect(maybeHost.get(), req.port)
    except OSError:
        # connection error host/port
        echo "Connection refused"
        await client.send("HTTP/1.1 502 Bad gateway\c\n\c\ndetox-proxy: connection refused (can't connect to requested server)\c\n")
        if not client.isClosed:
            client.close()
        return

    echo "CONNECTED " & req.path & ":" & $req.port
    if client.isClosed:
        safeClose(host, client)
        return

    if req.reqMethod == HttpMethod.Connect:
        await client.send("HTTP/1.1 200 Connection ESTABLISHED\c\n\c\n")
    else:
        if host.isClosed or client.isClosed:
            safeClose(host, client)
        await host.send(data)

    asyncCheck relay(client, host)
    asyncCheck relay(host, client)



proc serve*() {.async.} =
    var server = newAsyncSocket(buffered=false, domain=AF_INET6)
    server.setSockOpt(OptReuseAddr, true)
    server.setSockOpt(OptReusePort, true)
    server.bindAddr(Port(5001), "0.0.0.0")
    server.listen()

    while true:
        let client = await server.accept()
        asyncCheck processClient(client)
