local vfs = require("valu.vfs")
local ofs = fs
local mainfs = vfs.createAPI(ofs)
_G.fs = mainfs.fs

