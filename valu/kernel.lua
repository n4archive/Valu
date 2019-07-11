function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
 end
local vfs = require("valu.vfs")
local ofs = fs
local mainfs = vfs.createAPI(ofs)
_G.fs = mainfs.fs

