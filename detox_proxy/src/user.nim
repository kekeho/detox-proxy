import asynchttpserver
import httpclient
import asyncdispatch
import common
import options
import json
import strutils


type
    User = object
        username: string
        hashedPassword: string


var userlist {.threadvar.}: seq[User]



proc registUser(req: Request) {.async.} =
    let request_json_str: string = req.body.replace('\'', '"')
    let jsonNode = parseJson(request_json_str)

    try:
        let username: string = jsonNode["username"].getStr()
        let hashedPasswd: string = jsonNode["hashed_password"].getStr()
        let user = User(username: username, hashedPassword: hashedPasswd)
        userlist.add(user)
    
    except KeyError:
        await req.respond(Http422, "Validation Error")
    await req.respond(Http201, "Registered")



proc userCb(req: Request) {.async.} =
    try:
        if req.reqMethod == HttpPost and req.url.path == "/regist":
            await registUser(req)
        else:
            await req.respond(Http404, "404 Not Found")
    except Exception:
        await req.respond(Http500, "Internal Server Error")


proc serveUserServer*() {.async.} =
    let userServer = newAsyncHttpServer()
    asyncCheck userServer.serve(Port(5002), userCb, "0.0.0.0")
