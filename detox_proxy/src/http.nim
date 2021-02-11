import asyncdispatch
import net
import tables
import strutils
import options


type
    HttpMethod* = enum
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
        path*: string
        port*: Port
        protocol*: string
        body*: string


proc hasHeader(t: Table[string, auto], key: string): bool =
    if t.hasKey(key):
        return true

    for k in t.keys:
        if k.toUpper == key.toUpper:
            return true
    
    return false


proc getHeader*[T](t: Table[string, T], key: string): Option[T] =
    for k in t.keys:
        if k.toUpper == key.toUpper:
            return some(t[k])
    
    return none(T)


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


proc httpRequestParser*(raw: string): Option[HttpRequest] =
    var req = HttpRequest()
    let lines = raw.split("\c\n")
    try:
        # Method, path, protocol
        let method_path_proto_raw = lines[0]
        let method_path_proto_splitted = method_path_proto_raw.split(" ")

        let method_type: Option[HttpMethod] = toMethod(method_path_proto_splitted[0])
        if method_type.isNone():
            return none(HttpRequest)
        req.reqMethod = method_type.get()

        let path_raw = method_path_proto_splitted[1]
        if ":" in path_raw.replace("://", ""):
            # port-number provided
            let path_port = path_raw.split(":")
            let path = path_raw.split(":")[len(path_port)-2].strip
            let port = path_raw.split(":")[len(path_port)-1].strip.parseInt
            req.path = path; req.port = Port(port)
        else:
            req.path = path_raw
            req.port = Port(80)
        req.protocol = method_path_proto_splitted[2]

        # Header
        var idx: int = 0
        for idx, h in lines[1..len(lines)-1]:
            if not (":" in h):
                break  # end of header

            let key = h.split(":")[0].strip()
            let value = h.split(":")[1].strip()

            if req.headers.hasHeader(key):
                # Join with comma https://tools.ietf.org/html/rfc7230#section-3.2
                req.headers[key] = (req.headers[key] & ", " & value)
            else:
                req.headers[key] = value
        
        # Body
        let body_raw = raw.split("\n")[idx+1..len(lines)-1].join("\n")
        req.body = body_raw
    except IndexDefect, ValueError:
        return none(HttpRequest)

    return some(req)