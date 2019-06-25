local vfs = require("valu.vfs")
local ofs = fs
local mainfs = vfs.createAPI(ofs)
--fs = mainfs.fs
print(mainfs.mounts.debug("/bla"))
