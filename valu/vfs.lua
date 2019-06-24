local mountscreator = require("valu.mounts")
local rpw = function (fnc,fnc2,mounts)
  return function (path)
    if mounts.isReal(path) then
      return fnc(mounts.getrealpath(path))
    else
      return fnc2(mounts.getrelapath(path))
    end
  end
end
return {
  createAPI = function (ofs)
        local mounts = mountscreator(ofs);
        local fst = {
          combine=ofs.combine,
          list=rpw(ofs.list,mounts.list,mounts),
          exists=rpw(ofs.exists,mounts.exists,mounts),
          isDir=rpw(ofs.isDir,mounts.isDir,mounts),
          getSize=rpw(ofs.getSize,mounts.getSize,mounts),
          getFreeSpace=rpw(ofs.getFreeSpace,mounts.getFreeSpace,mounts),
          makeDir=rpw(ofs.makeDir,mounts.makeDir,mounts),
          move=function(fromPath,toPath)
            -- TODO
          end,
          copy=function(fromPath,toPath)
            -- TODO
          end,
          getDrive=function(path)
            -- TODO
          end,
          getName=ofs.getName,
          open=function (path,mode)
           -- TODO
          end,
          find=function(wildcard)
            -- TDOD
          end,
          getDir=ofs.getDir,
          complete=function(p1,p2,p3,p4)
            -- TODO
          end
        }
        return {fs=fs,mounts=mounts}
  end
}
