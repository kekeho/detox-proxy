import asyncnet
import asyncdispatch
import net
import nativesockets
import options

import common


let ctx = newContext(certFile="cert.crt", keyFile="cert.key")


proc processClient(client: AsyncSocket) {.async.} =
    echo "New proxy connection"

    var data: string
    try:
        data = await client.recv(1024)
    except SslError:
        echo "SSL ERROR"
        client.close()
        return

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

    await client.send("HTTP/1.1 200 Connection ESTABLISHED\c\n\c\n")


    asyncCheck relay(client, host)
    asyncCheck relay(host, client)



proc serve*() {.async.} =
    var server = newAsyncSocket(buffered=false, domain=AF_INET6)
    ctx.wrapSocket(server)
    server.setSockOpt(OptReuseAddr, true)
    server.setSockOpt(OptReusePort, true)
    server.bindAddr(Port(5001), "0.0.0.0")
    server.listen()

    while true:
        let client = await server.accept()
        try:
            # handshake to client
            ctx.wrapConnectedSocket(client, handshakeAsServer)
            if not client.isSsl:
                client.close()
        except SslError:
            echo "SSL Handshake failed"
            client.close()

        if not client.isClosed:
            asyncCheck processClient(client)
