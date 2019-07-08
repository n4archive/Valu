return function(ofs)
  function split(a,b)local c={}local d="(.-)"..b;local e=1;local f,g,h=a:find(d,1)while f do if f~=1 or h~=""then table.insert(c,h)end;e=g+1;f,g,h=a:find(d,e)end;if e<=#a then h=a:sub(e)table.insert(c,h)end;return c end
  function split_path(a)return split(a,'[\\/]+')end
  local mountpoints = {["/"]={isReal=true,realPath="/ccx",readOnly=false},["/rom"]={isReal=true,realPath="/rom",readOnly=false}}
  function _findmounthelp(path)
    local x = split_path(path)
    for i = #x,1,-1 do
      local p  = "/" .. table.concat(x,"/",1,i);
      if mountpoints[p] ~= nil then
        local r = "/" .. table.concat(x,"/",i+1,#x)
        if r == p then
          r = "/"
        end
        return p,r
      end
    end
  end
  function _findmount(path)
    local x,y = _findmounthelp(path)
    if not x and not y then
      return "/", path
    end
    return x,y
  end
  function _wopen(path,mode)
    local drive, folder = _findmount(path)
    return mountpoints[drive].fse.open(folder,mode)
  end
  return {
    movePolyfill = true,
    getrealpath = function(path)
      local drive, folder = _findmount(path)
      return ofs.combine(mountpoints[drive].realPath,folder)
    end,
    getrelapath = function(path)
      local drive, folder = _findmount(path)
      return folder
    end,
    isReal = function(path)
      local drive, folder = _findmount(path)
      return mountpoints[drive].isReal
    end,
    delete = function(path) local drive, folder = _findmount(path) if not mountpoints[drive].readOnly then mountpoints[drive].fse.delete(folder) else error(path .. ": Access denied") end end,
    list = function(path) local drive, folder = _findmount(path) mountpoints[drive].fse.list(folder) end,
    exists = function(path) local drive, folder = _findmount(path) mountpoints[drive].fse.exists(folder) end,
    isDir = function(path) local drive, folder = _findmount(path) mountpoints[drive].fse.isDir(folder) end,
    getSize = function(path) local drive, folder = _findmount(path) mountpoints[drive].fse.getSize(folder) end,
    getFreeSpace = function(path) local drive, folder = _findmount(path) mountpoints[drive].fse.getFreeSpace(folder) end,
    makeDir = function(path) local drive, folder = _findmount(path) if not mountpoints[drive].readOnly then mountpoints[drive].fse.makeDir(folder) else error(path .. ": Access denied") end end,
    move = function(from,to)
        local fdrive, ffolder = _findmount(from)
        local tdrive, tfolder = _findmount(to)
        if not mountpoints[tdrive].readOnly then
            error("Move not implemented")
        else error(to .. ": Access denied") end
    end,
    copy = function(from,to)
        local fdrive, ffolder = _findmount(from)
        local tdrive, tfolder = _findmount(to)
        if not mountpoints[tdrive].readOnly then
            local fhandle = _wopen(from,"r")
            local thandle = _wopen(to,"w")
            thandle.write(fhandle.readAll())
            thandle.close()
            fhandle.close()
        else error(to .. ": Access denied") end
    end,
    open = function(path,mode)
      return _wopen(path,mode)
    end,
    pflist = function(path,appto)
        -- TODO
    end,
  }
end
