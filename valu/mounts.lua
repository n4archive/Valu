return function(ofs)
  local split = function(inputstr,sep)sep=sep or '%s' local t={} for field,s in string.gmatch(inputstr,"([^"..sep.."]*)("..sep..")") do table.insert(t,field) if s=="" then return t end end end
  local mountpoints = {["/"]={}}
  function _findmount(path)
    -- TODO
  end
  end
  return {
    getrealpath = function(path)
      local drive, folder = _findmount(path)
      return mountpoints[drive].realPath
    end,
    getrelapath = function(path)
      local drive, folder = _findmount(path)
      return folder
    end,
    isReal = function(path)
      local drive, folder = _findmount(path)
      return mountpoints[drive].isReal
    end,
    debug = function(path)
      return _findmount(path)
    end
  }
end
