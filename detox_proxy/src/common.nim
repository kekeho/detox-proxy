# Copyright (c) 2021 Hiroki Takemura (kekeho)

# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import asyncdispatch
import net
import asyncnet
import tables
import strutils
import options
import times
import base64


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
    Basic* = object
        username*: string
        password*: string


type
    HttpRequest = object
        headers*: Table[string, string]
        reqMethod*: HttpMethod
        path*: string
        port*: Port
        protocol*: string
        body*: string
        basic*: Option[Basic]

type
    Connection = ref object
        a: AsyncSocket
        b: AsyncSocket
        last_timestamp: int64  # unix timestamp


proc safeClose*(a: AsyncSocket, b: AsyncSocket) =
    if not a.isClosed:
        a.close()
    if not b.isClosed:
        b.close()


proc safeClose*(conn: Connection) =
    echo "disconnected"
    safeClose(conn.a, conn.b)



var connlist {.threadvar.}: seq[Connection]


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
            echo "METHOD TYPE IS NONE " & raw
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

        # Basic
        let auth = req.headers.getHeader("Proxy-Authorization")
        if auth.isNone:
            req.basic = none(Basic)
        else:
            let type_and_cred: string = auth.get()
            let typ = type_and_cred.split(' ')[0]
            if typ != "Basic":
                return none(HttpRequest)

            let cred = base64.decode(type_and_cred.split(" ")[1]).split(':')
            let
                username: string = cred[0]
                pass: string = cred[1]
            req.basic = some(Basic(username: username, password: pass))
    except IndexDefect, ValueError:
        return none(HttpRequest)

    return some(req)


proc connwatch*() {.async.} =
    const nodata_timelimit = 120 # 120s (from last recv/send)

    var count = 0
    while true:
        var new_connlist: seq[Connection]
        let nowUnix = now().toTime.toUnix
        for i, conn in connlist:
            # timestamp check
            if (nowUnix - conn.last_timestamp) > nodata_timelimit:
                echo "TIMEOUT"
                safeClose(conn)
            elif conn.a.isClosed or conn.b.isClosed:
                safeClose(conn)
            else:
                new_connlist.add(conn)

        connlist = new_connlist
        count += 1
        await sleepAsync(500)

        if count == 4:
            echo "===== CONNECTIONS ===="
            echo connlist.len
            count = 0


proc relay*(from_socket: AsyncSocket, to_socket: AsyncSocket) {.async.} =
    let conn = Connection(
        a: from_socket, b: to_socket,
        last_timestamp: now().toTime.toUnix,
    )
    connlist.add(conn)
    while true:
        if conn.a.isClosed or conn.b.isClosed:
            safeClose(conn)
            return
        
        try:
            let data = await conn.a.recv(1024)
            if data.len == 0:
                safeClose(conn)
                return
            await conn.b.send(data)
            conn.last_timestamp = now().toTime.toUnix
        except OSError, ValueError:
            safeClose(conn)
            return
