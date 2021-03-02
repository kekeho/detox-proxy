import asynchttpserver
import uri
import httpclient
import asyncdispatch
import common
import tables
import json
import strutils
import sequtils
import easy_bcrypt
import sugar



type
    Block = object
        user: string
        url: Uri
        startTime: int
        endTime: int
        active: bool


type
    User = object
        username: string
        hashedPassword: string
        blockList: seq[Block]


var userlist {.threadvar.}: Table[string, User]  # username: User


proc registUser(req: Request) {.async.} =
    let request_json_str: string = req.body.replace('\'', '"')
    let jsonNode = parseJson(request_json_str)

    try:
        let username: string = jsonNode["username"].getStr()
        let hashedPasswd: string = jsonNode["hashed_password"].getStr()
        let user = User(username: username, hashedPassword: hashedPasswd)
        userlist[username] = user
    except KeyError:
        await req.respond(Http422, "Validation Error")

    await req.respond(Http201, "Registered")



proc userCb(req: Request) {.async.} =
    try:
        if req.reqMethod == HttpPost and req.url.path == "/user/regist":
            await registUser(req)
        else:
            await req.respond(Http404, "404 Not Found")
    except Exception:
        await req.respond(Http500, "Internal Server Error")


proc serveUserServer*() {.async.} =
    let userServer = newAsyncHttpServer()
    asyncCheck userServer.serve(Port(5002), userCb, "0.0.0.0")


proc auth*(basic: Basic): bool =
    echo userlist
    var u: User
    try:
        u = userlist[basic.username]    
    except KeyError:
        return false

    let hashedPw = loadPasswordSalt(u.hashedPassword)
    let inputHashedPw = hashPw( basic.password, loadPasswordSalt(u.hashedPassword) )

    if (u.username == basic.username) and ( hashedPw == inputHashedPw ):
        return true
    else:
        return false
