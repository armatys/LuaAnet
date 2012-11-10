package = "anet"
version = "1.0-1"

source = {
  url = "https://github.com/armatys/LuaAnet"
}

description = {
  summary = "Socket utilities",
  detailed = [[
    Lua socket utilities library.
  ]],
  homepage = "https://github.com/armatys/LuaAnet",
  license = "MIT/X11"
}

dependencies = {
  "lua >= 5.1"
}

supported_platforms = { "macosx", "freebsd", "linux" }

build = {
  type = "builtin",
  anet = "lua/anet/init.lua",
  ["anet.handlers"] = "lua/anet/handlers.lua",
  modules = {
    anetc = {
      sources = {
        "src/anet.c",
        "src/main.c",
      }
    }
  }
}
