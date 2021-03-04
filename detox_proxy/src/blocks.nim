import asynchttpserver
import uri
import httpclient
import asyncdispatch
import tables
import json
import strutils
import hashes
import times
import options



type
    Block = object
        url: Uri
        startTime: int
        endTime: int
        active: bool


proc hash(b: Block): Hash =
    return hash($b.url)


var accessLog {.threadvar.}: Table[Block, Option[DateTime]]  # block: first access


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

    var blockList: seq[Block]
    try:
        for b in blockNode.getElems():
            let blockObj = Block(
                url: parseUri(b["url"].getStr),
                startTime: b["start"].getInt,
                endTime: b["end"].getInt,
                active: b["active"].getBool,
            )
            blockList.add(blockObj)
    except KeyError:
        await req.respond(Http422, "Validation Error")
        return

    for b in blockList:
        var oldVal: Option[DateTime]
        try:
            oldVal = accessLog[b]
        except KeyError:
            oldVal = none(DateTime)
        accessLog[b] = oldVal
    
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
    # hash(block)は, hash($block.url)なので, urlが一緒ならマッチする
    let dummyBlock = Block(url: address)

    var
        maybeLog: Option[DateTime]
        blockObj: Block
    try:
        maybeLog = accessLog[dummyBlock]
    except KeyError:
        return true

    for b, l in accessLog.pairs():
        if hash(b) == hash(dummyBlock):
            blockObj = b
            maybeLog = l

    if blockObj.active == false:
        return true

    if maybeLog.isNone:
        accessLog[blockObj] = some(now())
        return true

    let log = maybeLog.get()
    if now() - log > initDuration(minutes=blockObj.startTime):
        if now() - log > initDuration(minutes=blockObj.startTime + blockObj.endTime):
            accessLog[blockObj] = none(DateTime)
            return true
        else:
            return false

    return true
