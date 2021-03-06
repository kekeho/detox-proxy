# Copyright (c) 2020 Hiroki Takemura (kekeho) and Aizack

# This software is released under the MIT License.
# https://opensource.org/licenses/MIT


import asyncdispatch
import docopt

import proxy
import blocks
import common


const VERSION = "0.1.0"
const DOC = """
　   _      _                                            
  __| | ___| |_ _____  __     _ __  _ __ _____  ___   _  
 / _` |/ _ \ __/ _ \ \/ /____| '_ \| '__/ _ \ \/ / | | | 
| (_| |  __/ || (_) >  <_____| |_) | | | (_) >  <| |_| | 
 \__,_|\___|\__\___/_/\_\    | .__/|_|  \___/_/\_\\__, | 
                             |_|                  |___/ 

detox_proxy
Copyright: Hiroki Takemura (kekeho) All Rights Reserved.

Usage:
    detox_proxy

Options:
    -h --help       Show this help
    -v --version    Show version info
"""

when isMainModule:
    discard docopt(DOC, version=VERSION)
    asyncCheck serveBlocksServer()
    asyncCheck proxy.serve()
    asyncCheck connwatch()
    runForever()
