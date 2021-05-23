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
function string.gsplit(text, pattern, plain)
    local splitStart, length = 1, #text
    return function ()
      if splitStart then
        local sepStart, sepEnd = string.find(text, pattern, splitStart, plain)
        local ret
        if not sepStart then
          ret = string.sub(text, splitStart)
          splitStart = nil
        elseif sepEnd < sepStart then
          -- Empty separator!
          ret = string.sub(text, splitStart, sepStart)
          if sepStart < length then
            splitStart = sepStart + 1
          else
            splitStart = nil
          end
        else
          ret = sepStart > splitStart and string.sub(text, splitStart, sepStart - 1) or ''
          splitStart = sepEnd + 1
        end
        return ret
      end
    end
end
function string.split(text, pattern, plain)
    local ret = {}
    for match in string.gsplit(text, pattern, plain) do
      table.insert(ret, match)
    end
    return ret
end

local kernel = require("valu.api")
local vfs = require("valu.vfs")
local ofs = fs
local mainfs = vfs.createAPI(ofs, kernel)
_G.fs = mainfs.fs
print("injected fs")
