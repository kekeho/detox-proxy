# Copyright (c) 2020 Hiroki Takemura (kekeho) and Aizack
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT


import asyncdispatch
import httpclient
import asynchttpserver
import uri


proc callback(req: Request) {.async.} =
  echo "URL"
  echo $req.url

  # Connect to requested host
  let client = newAsyncHttpClient()
  let response: AsyncResponse = await client.request($req.url, req.reqMethod, req.body, req.headers)

  # Get data from requested host
  var body: string = ""
  let (isExist, bodyStreamResult) = await response.bodyStream.read
  if isExist:
    body =  bodyStreamResult

  # Return response to client
  await req.respond(response.code, body, response.headers)


proc main =
  let server = newAsyncHttpServer()
  waitFor server.serve(Port(5000), callback)


when isMainModule:
  main()