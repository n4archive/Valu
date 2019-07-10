local mountscreator = require("valu.mounts")
local rpw = function (fnc,fnc2,mounts,ofs)
  return function (path)
    if mounts.isReal(path) then
      return fnc("/"..mounts.getrealpath(path))
    else
      return fnc2(path)
    end
  end
end
local rpwc = function (fnc,fnc2,mounts,ofs)
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
local w = function(x)return x end
local lw=function(a,b,...)local r=b(...)return function(...)print(a)return(r(...)) end end
return {
  createAPI = function (ofs)
        local mounts = mountscreator(ofs);
        local fst = {
          combine=lw("fs.combine",w,ofs.combine),
          list=lw("fs.list",rpwc,function(path) return mounts.pflist(path,ofs.list) end,function(path) return mounts.pflist(path,mounts.list) end,mounts,ofs),
          exists=lw("fs.exists",rpw,ofs.exists,mounts.exists,mounts,ofs),
          isDir=lw("fs.isDir",rpwc,ofs.isDir,mounts.isDir,mounts,ofs),
          isReadOnly=lw("fs.isReadOnly",rpwc,ofs.isReadOnly,mounts.isReadOnly,mounts,ofs),
          getSize=lw("fs.getSize",rpwc,ofs.getSize,mounts.getSize,mounts,ofs),
          getFreeSpace=lw("fs.getFreeSpace",rpwc,ofs.getFreeSpace,mounts.getFreeSpace,mounts,ofs),
          makeDir=lw("fs.makeDir",rpw,ofs.makeDir,mounts.makeDir,mounts,ofs),
          delete=lw("fs.delete",rpwc,ofs.delete,mounts.delete,mounts,ofs),
          move=lw("fs.move",w,function(fromPath,toPath)
            if mounts.isReal(fromPath) and mounts.isReal(toPath) then
              ofs.move(mounts.getrealpath(fromPath),mounts.getrealpath(toPath))
            elseif mounts.movePolyfill then
              mounts.copy(fromPath,toPath)
              mounts.delete(fromPath)
            else
              mounts.move(fromPath,toPath)
            end
          end),
          copy=lw("fs.copy",w,function(fromPath,toPath)
            if mounts.isReal(fromPath) and mounts.isReal(toPath) then
              ofs.copy(mounts.getrealpath(fromPath),mounts.getrealpath(toPath))
            else
              mounts.copy(fromPath,toPath)
            end
          end),
          getDrive=lw("fs.getDrive",w,function(path)
            return "hdd"
          end),
          getName=lw("fs.getName",w,ofs.getName),
          open=lw("fs.open",w,function (path,mode)
            if mounts.isReal(path) then
              return ofs.open("/"..mounts.getrealpath(path),mode)
            else
              return mounts.open(path,mode)
            end
          end),
          find=lw("fs.find",w,function(wildcard)
            return {}
          end,
          getDir=lw("fs.getDir",w,ofs.getDir),
          complete=lw("fs.complete",w,function(p1,p2,p3,p4)
            local drive, folder = _findmount(p2)
            if not mounts.isReal(p2) then error("Complete not implemented") end
              return ofs.complete(p1,mounts.getrealpath(p2),p3,p4)
          end),
        }
        return {fs=fst,mounts=mounts}
  end
}
