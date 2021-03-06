import asynchttpserver
import uri
import httpclient
import asyncdispatch
import tables
import json
import strutils
import hashes
import times
import common
import options



type
    Block = object
        url: Uri
        startTime: int
        endTime: int
        active: bool


var blockList {.threadvar.}: Table[string, Block]
var accessLog {.threadvar.}: Table[string, Option[DateTime]]  # block address: first access


proc registBlock(req: Request) {.async.} =
    let request_json_str: string = req.body.replace('\'', '"')
    echo request_json_str
    var
        blockNode: JsonNode
    try:
        blockNode = parseJson(request_json_str)
    except KeyError, JsonParsingError:
        await req.respond(Http422, "Validation Error")
        return

    try:
        for b in blockNode.getElems():
            let blockObj = Block(
                url: parseUri(b["url"].getStr),
                startTime: b["start"].getInt,
                endTime: b["end"].getInt,
                active: b["active"].getBool,
            )
            blockList[blockObj.url.pickHost] = blockObj
    except KeyError:
        await req.respond(Http422, "Validation Error")
        return

    for address in blockList.keys():
        var oldVal: Option[DateTime]
        try:
            oldVal = accessLog[address]
        except KeyError:
            oldVal = none(DateTime)
        accessLog[address] = oldVal
    
    await req.respond(Http201, "Registered")
    return


proc userCb(req: Request) {.async.} =
    # TODO: methodが違うだけの場合は, method not allowedを返す
    try:
        if req.reqMethod == HttpPost and req.url.path == "/block/regist":
            await registBlock(req)
        else:
            await req.respond(Http404, "404 Not Found")
    except Exception:
        await req.respond(Http500, "Internal Server Error")


proc serveBlocksServer*() {.async.} =
    let userServer = newAsyncHttpServer()
    asyncCheck userServer.serve(Port(5002), userCb, "0.0.0.0")


proc isAccessable*(address: Uri): bool =
    echo "ACCESS CHECK"
    echo address

    var
        maybeLog: Option[DateTime]
    try:
        echo accessLog
        maybeLog = accessLog[pickHost(address)]
    except KeyError:
        echo "NO BLOCK"
        return true

    let blockObj = blockList[address.pickHost]
    echo "BLOCK LIST"
    echo blockObj.url

    if blockObj.active == false:
        return true

    if maybeLog.isNone:
        accessLog[address.pickHost] = some(now())
        return true

    let log = maybeLog.get()
    if now() - log > initDuration(minutes=blockObj.startTime):
        if now() - log > initDuration(minutes=blockObj.startTime + blockObj.endTime):
            accessLog[address.pickHost] = none(DateTime)
            return true
        else:
            return false

    return true
