loacl mounts = require("valu.mounts");
local rpw = function (fnc,fnc2)
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
        local fst = {
          combine=ofs.combine,
          list=rpw(ofs.list,mounts.list),
          exists=rpw(ofs.exists,mounts.exists),
          isDir=rpw(ofs.isDir,mounts.isDir),
          getSize=rpw(ofs.getSize,mounts.getSize),
          getFreeSpace=rpw(ofs.getFreeSpace,mounts.getFreeSpace),
          makeDir=rpw(ofs.makeDir,mounts.makeDir),
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
        return fst
  end
}
