-- Including https://pastebin.com/mWgvzszW
function string.starts(String, Start)
    return string.sub(String, 1, string.len(Start)) == Start
end
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end
local vfs = require("valu.vfs")
local ofs = fs
local mainfs = vfs.createAPI(ofs)
_G.fs = mainfs.fs
