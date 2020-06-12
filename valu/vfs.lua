local mountscreator = require("valu.mounts")
local rpw = function(fnc, fnc2, mounts, ofs)
  return function(path)
    local path = ofs.combine("/", path)
    if mounts.isReal(path) then
      return fnc("/" .. mounts.getrealpath(path))
    else
      return fnc2(path)
    end
  end
end
local rpwc = function(fnc, fnc2, mounts, ofs)
  return function(path)
    local path = ofs.combine("/", path)
    if mounts.isReal(path) then
      if not ofs.exists("/" .. mounts.getrealpath(path)) then
        error(path .. ": File not found", 3)
      end
      return fnc("/" .. mounts.getrealpath(path))
    else
      if not mounts.exists("/" .. path) then
        error(path .. ": File not found", 3)
      end
      return fnc2(path)
    end
  end
end
local _ls = function(fnc, fnc2, mounts, ofs)
  return function(path)
    local path = ofs.combine("/", path)
    if mounts.isReal(path) then
      if not ofs.exists("/" .. mounts.getrealpath(path)) then
        error(path .. ": File not found", 3)
      end
      return fnc(path, "/" .. mounts.getrealpath(path))
    else
      if not mounts.exists("/" .. path) then
        error(path .. ": File not found", 3)
      end
      return fnc2(path)
    end
  end
end
local w = function(x)
  return x
end
local log_fscall = false
local lw = function(a, b, ...)
  local r = b(...)
  return (function(...)
    if (log_fscall) then
      print(a)
    end
    return (r(...))
  end)
end
return {
  createAPI = function(ofs)
    local mounts = mountscreator(ofs)
    local fst = {
      combine = lw("fs.combine", w, ofs.combine),
      list = lw(
        "fs.list",
        _ls,
        function(path, rpath)
          return mounts.pflist(path, rpath, ofs.list)
        end,
        function(path)
          return mounts.pflist(path, path, mounts.list)
        end,
        mounts,
        ofs
      ),
      exists = lw("fs.exists", rpw, ofs.exists, mounts.exists, mounts, ofs),
      isDir = lw("fs.isDir", rpw, ofs.isDir, mounts.isDir, mounts, ofs),
      isReadOnly = lw(
        "fs.isReadOnly",
        function(f, ofs)
          return function(path)
            return f(ofs.combine("/", path))
          end
        end,
        mounts.isReadOnly,
        ofs
      ),
      getSize = lw("fs.getSize", rpwc, ofs.getSize, mounts.getSize, mounts, ofs),
      getFreeSpace = lw("fs.getFreeSpace", rpwc, ofs.getFreeSpace, mounts.getFreeSpace, mounts, ofs),
      makeDir = lw("fs.makeDir", rpw, ofs.makeDir, mounts.makeDir, mounts, ofs),
      delete = lw("fs.delete", rpwc, ofs.delete, mounts.delete, mounts, ofs),
      move = lw(
        "fs.move",
        w,
        function(fromPath, toPath)
          local fromPath = ofs.combine("/", fromPath)
          local toPath = ofs.combine("/", toPath)
          if mounts.isReal(fromPath) and mounts.isReal(toPath) then
            ofs.move(mounts.getrealpath(fromPath), mounts.getrealpath(toPath))
          elseif mounts.movePolyfill then
            mounts.copy(fromPath, toPath)
            mounts.delete(fromPath)
          else
            mounts.move(fromPath, toPath)
          end
        end
      ),
      copy = lw(
        "fs.copy",
        w,
        function(fromPath, toPath)
          local fromPath = ofs.combine("/", fromPath)
          local toPath = ofs.combine("/", toPath)
          if mounts.isReal(fromPath) and mounts.isReal(toPath) then
            ofs.copy(mounts.getrealpath(fromPath), mounts.getrealpath(toPath))
          elseif mounts.isReal(fromPath) and not mounts.isReal(toPath) then
            mounts.copy(mounts.getrealpath(fromPath), toPath, true, false)
	  elseif not mounts.isReal(fromPath) and mounts.isReal(toPath) then
            mounts.copy(fromPath, mounts.getrealpath(toPath), false, true)
	  else
	    mounts.copy(fromPath, toPath, false, false)
          end
        end
      ),
      getDrive = lw(
        "fs.getDrive",
        w,
        function(path)
          local path = ofs.combine("/", path)
          return "hdd"
        end
      ),
      getName = lw("fs.getName", w, ofs.getName),
      open = lw(
        "fs.open",
        w,
        function(path, mode)
          local path = ofs.combine("/", path)
          if mounts.isReal(path) then
            return ofs.open("/" .. mounts.getrealpath(path), mode)
          else
            return mounts.open(path, mode)
          end
        end
      ),
      find = lw(
        "fs.find",
        w,
        function(path)
          -- https://pastebin.com/mWgvzszW
          local pathParts, results, curfolder = {}, {}, "/"
          for part in path:gmatch("[^/]+") do
            pathParts[#pathParts + 1] = part:gsub("*", "[^/]*")
          end
          if #pathParts == 0 then
            return {}
          end
          local prospects = fs.list(curfolder)
          for i = 1, #prospects do
            prospects[i] = {["parent"] = curfolder, ["depth"] = 1, ["name"] = prospects[i]}
          end

          while #prospects > 0 do
            local thisProspect = table.remove(prospects, 1)
            local fullPath = fs.combine(thisProspect.parent, thisProspect.name)

            if thisProspect.name == thisProspect.name:match(pathParts[thisProspect.depth]) then
              if thisProspect.depth == #pathParts then
                results[#results + 1] = fullPath
              elseif fs.isDir(fullPath) and thisProspect.depth < #pathParts then
                local newList = fs.list(fullPath)
                for i = 1, #newList do
                  prospects[#prospects + 1] = {
                    ["parent"] = fullPath,
                    ["depth"] = thisProspect.depth + 1,
                    ["name"] = newList[i]
                  }
                end
              end
            end
          end
          return results
        end
      ),
      getDir = lw("fs.getDir", w, ofs.getDir),
      complete = lw("fs.complete", w, ofs.complete)
    }
    return {fs = fst, mounts = mounts}
  end
}
