vfs = require("valu.vfs")
ofs = fs
mainfs = vfs.createAPI(ofs)
fs = mainfs.getFs()

