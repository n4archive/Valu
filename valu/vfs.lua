local mountscreator = require("valu.mounts")
local rpw = function (fnc,fnc2,mounts)
  return function (path)
    if mounts.isReal(path) then
      return fnc("/"..mounts.getrealpath(path))
    else
      return fnc2(path)
    end
  end
end
local rpwc = function (fnc,fnc2,mounts)
  return function (path)
    if mounts.isReal(path) then
      if not ofs.exists("/"..mounts.getrealpath(path)) then error(path..": File not found") end
      return fnc("/"..mounts.getrealpath(path))
    else
      if not mounts.exists("/"..mounts.getrelapath(path)) then error(path..": File not found") end
      return fnc2(path)
    end
  end
end
return {
  createAPI = function (ofs)
        local mounts = mountscreator(ofs);
        local fst = {
          combine=ofs.combine,
          list=rpwc(function(path) return mounts.pflist(path,ofs.list) end,function(path) return mounts.pflist(path,mounts.list) end,mounts),
          exists=rpw(ofs.exists,mounts.exists,mounts),
          isDir=rpwc(ofs.isDir,mounts.isDir,mounts),
          isReadOnly=rpwc(ofs.isReadOnly,mounts.isReadOnly,mounts),
          getSize=rpwc(ofs.getSize,mounts.getSize,mounts),
          getFreeSpace=rpwc(ofs.getFreeSpace,mounts.getFreeSpace,mounts),
          makeDir=rpw(ofs.makeDir,mounts.makeDir,mounts),
          delete=rpwc(ofs.delete,mounts.delete,mounts),
          move=function(fromPath,toPath)
            if mounts.isReal(fromPath) and mounts.isReal(toPath) then
              ofs.move(mounts.getrealpath(fromPath),mounts.getrealpath(toPath))
            elseif mounts.movePolyfill then
              mounts.copy(fromPath,toPath)
              mounts.delete(fromPath)
            else
              mounts.move(fromPath,toPath)
            end
          end,
          copy=function(fromPath,toPath)
            if mounts.isReal(fromPath) and mounts.isReal(toPath) then
              ofs.copy(mounts.getrealpath(fromPath),mounts.getrealpath(toPath))
            else
              mounts.copy(fromPath,toPath)
            end
          end,
          getDrive=function(path)
            return "hdd"
          end,
          getName=ofs.getName,
          open=function (path,mode)
            if mounts.isReal(path) then
              return ofs.open("/"..mounts.getrealpath(path),mode)
            else
              return mounts.open(path,mode)
            end
          end,
          find=function(wildcard)
            return {}
          end,
          getDir=ofs.getDir,
          complete=function(p1,p2,p3,p4)
            local drive, folder = _findmount(p2)
            if not mounts.isReal(p2) then error("Complete not implemented") end
              return ofs.complete(p1,mounts.getrealpath(p2),p3,p4)
          end
        }
        return {fs=fst,mounts=mounts}
  end
}
