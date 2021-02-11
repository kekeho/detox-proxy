import asyncdispatch
import asyncnet
import net
import tables
import strutils
import options


type
    HttpMethod = enum
        Head,
        Get,
        Post,
        Put,
        Patch,
        Delete,
        Trace,
        Options,
        Connect,


type
    HttpRequest = object
        headers*: Table[string, string]
        reqMethod*: HttpMethod
        body*: string


proc toMethod(str: string): Option[HttpMethod] =
    case str
    of "HEAD":
        return some(HttpMethod.Head)
    of "GET":
        return some(HttpMethod.Get)
    of "POST":
        return some(HttpMethod.Post)
    of "PUT":
        return some(HttpMethod.Put)
    of "PATCH":
        return some(HttpMethod.Patch)
    of "DELETE":
        return some(HttpMethod.Delete)
    of "TRACE":
        return some(HttpMethod.Trace)
    of "OPTIONS":
        return some(HttpMethod.Options)
    of "CONNECT":
        return some(HttpMethod.Connect)

    return none(HttpMethod)


proc httpRequestParser(raw: string): Option[HttpRequest] =
    var req = HttpRequest()
    let lines = raw.split("\n")
    try:
        # Method
        let method_raw = lines[0]
        let method_raw_splitted = method_raw.split(" ")
        let method_type: Option[HttpMethod] = toMethod(method_raw_splitted[0])
        if method_type.isNone():
            return none(HttpRequest)
        req.reqMethod = method_type.get()

        # Header
        var idx: int = 0
        for idx, h in lines[1..len(lines)-1]:
            if not (":" in h):
                echo "break"
                break  # end of header

            let key = h.split(":")[0].strip()
            let value = h.split(":")[1].strip()

            if req.headers.hasKey(key):
                # Join with comma https://tools.ietf.org/html/rfc7230#section-3.2
                req.headers[key] = (req.headers[key] & ", " & value)
            else:
                req.headers[key] = value
        
        # Body
        let body_raw = raw.split("\n")[idx+1..len(lines)-1].join("\n")
        req.body = body_raw
    except IndexDefect:
        return none(HttpRequest)

    return some(req)


proc relay(from_socket: AsyncSocket, to_socket: AsyncSocket) {.async.} =
    while true:
        let data = await from_socket.recv(BufferSize)
        let maybeReq = httpRequestParser(data)
        if maybeReq.isNone():
            if not from_socket.isClosed:
                from_socket.close()
            elif not to_socket.isClosed:
                to_socket.close()
            return
        
        let req = maybeReq.get()
        echo req.headers
        if data.len == 0: break
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
