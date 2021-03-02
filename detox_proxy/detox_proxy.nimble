# Package

version       = "0.1.0"
author        = "Hiroki.T"
description   = "Proxy for SNS detox"
license       = "MIT"
srcDir        = "src"
bin           = @["detox_proxy"]


# Dependencies

requires "nim >= 1.4.2"
requires "docopt >= 0.6.8"
requires "easy_bcrypt >= 2.0.3"
