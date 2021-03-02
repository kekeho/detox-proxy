import asynchttpserver
import uri
import httpclient
import asyncdispatch
import common
import tables
import json
import strutils
import easy_bcrypt
import sets
import hashes
import times
import options



type
    Block = object
        url: Uri
        startTime: int
        endTime: int
        active: bool


type
    User = object
        username: string
        hashedPassword: string
        blockList: HashSet[Block]


proc hash(b: Block): Hash =
    return hash($b.url)


var userlist {.threadvar.}: Table[string, User]  # username: User
var accessLog {.threadvar.}: Table[Block, Option[DateTime]]  # block: first access


proc registUser(req: Request) {.async.} =
    let request_json_str: string = req.body.replace('\'', '"')
    try:
        let jsonNode = parseJson(request_json_str)
        let username: string = jsonNode["username"].getStr()
        let hashedPasswd: string = jsonNode["hashed_password"].getStr()
        let user = User(username: username, hashedPassword: hashedPasswd)
        userlist[username] = user
    except KeyError, JsonParsingError:
        await req.respond(Http422, "Validation Error")

    await req.respond(Http201, "Registered")


proc registBlock(req: Request) {.async.} =
    let request_json_str: string = req.body.replace('\'', '"')
    echo request_json_str
    var
        username: string
        blockNode: JsonNode
    try:
        let jsonNode = parseJson(request_json_str)
        username = jsonNode["username"].getStr()
        blockNode = jsonNode["block"]
    except KeyError, JsonParsingError:
        await req.respond(Http422, "Validation Error")
        return

    var blockList: HashSet[Block]
    try:
        for b in blockNode.getElems():
            let blockObj = Block(
                url: parseUri(b["url"].getStr),
                startTime: b["start"].getInt,
                endTime: b["end"].getInt,
                active: b["active"].getBool,
            )
            blockList = blockList + toHashSet([blockObj,])
    except KeyError:
        await req.respond(Http422, "Validation Error")
        return
    
    try:
        userlist[username].blockList = blockList
    except KeyError:
        await req.respond(Http404, "User not found")
    
    await req.respond(Http201, "Registered")
    echo userlist[username].blockList
    return


proc userCb(req: Request) {.async.} =
    # TODO: methodが違うだけの場合は, method not allowedを返す
    try:
        if req.reqMethod == HttpPost and req.url.path == "/user/regist":
            await registUser(req)
        elif req.reqMethod == HttpPost and req.url.path == "/user/block/regist":
            await registBlock(req)
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


proc isAccessable*(username: string, address: Uri): bool =
    let u: User = userlist[username]
    for b in u.blockList:
        if b.url == address:
            return false  # TODO: 時間で遮断に直す
    
    return true
