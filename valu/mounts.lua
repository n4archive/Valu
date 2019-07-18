return function(ofs)
  function split(a, b)
    local c = {}
    local d = "(.-)" .. b
    local e = 1
    local f, g, h = a:find(d, 1)
    while f do
      if f ~= 1 or h ~= "" then
        table.insert(c, h)
      end
      e = g + 1
      f, g, h = a:find(d, e)
    end
    if e <= #a then
      h = a:sub(e)
      table.insert(c, h)
    end
    return c
  end
  function split_path(a)
    return split(a, "[\\/]+")
  end
  local mountpoints = {
    ["/"] = {isReal = true, realPath = "/ccx/valu", readOnly = true},
    ["/test"] = {isReal = true, realPath = "/rom", readOnly = true},
    ["/rom"] = {isReal = true, realPath = "/rom", readOnly = true},
    ["/v"] = {isReal = false, readOnly = false, fse = require("valu.ramfs")()}
  }
  function _findmounthelp(path)
    local x = split_path(path)
    for i = #x, 1, -1 do
      local p = "/" .. table.concat(x, "/", 1, i)
      if mountpoints[p] ~= nil then
        local r = "/" .. table.concat(x, "/", i + 1, #x)
        if r == p then
          r = "/"
        end
        return p, r
      end
    end
  end
  local _findmount = function(path)
    local x, y = _findmounthelp(path)
    if not x and not y then
      return "/", path
    end
    return x, y
  end
  local _wopen = function(path, mode)
    local drive, folder = _findmount(path)
    return mountpoints[drive].fse(folder, mode)
  end
  local _ro = function(path)
    local drive, folder = _findmount(path)
    local x = false
    local f = false
    if mountpoints[drive].isReal then
      x = ofs.isReadOnly(mountpoints[drive].realPath)
    else
      if mountpoints[drive].fse(ofs.combine(folder, ".."), "s") ~= nil then
        f = mountpoints[drive].fse(ofs.combine(folder, ".."), "s").readOnly
      end
    end
    return f or mountpoints[drive].readOnly or x
  end
  return {
    movePolyfill = true,
    mountpoints = mountpoints,
    getrealpath = function(path)
      local drive, folder = _findmount(path)
      return ofs.combine(mountpoints[drive].realPath, folder)
    end,
    getrelapath = function(path)
      local drive, folder = _findmount(path)
      return folder
    end,
    isReal = function(path)
      local drive, folder = _findmount(path)
      return mountpoints[drive].isReal
    end,
    delete = function(path)
      local drive, folder = _findmount(path)
      if not mountpoints[drive].fse(ofs.combine(folder, ".."), "s").readOnly then
        mountpoints[drive].fse(folder, "d")
      else
        error(path .. ": Access denied")
      end
    end,
    list = function(path)
      local drive, folder = _findmount(path)
      return mountpoints[drive].fse(folder, "l")
    end,
    exists = function(path)
      local drive, folder = _findmount(path)
      return mountpoints[drive].fse(folder, "s") ~= nil
    end,
    isDir = function(path)
      local drive, folder = _findmount(path)
      return mountpoints[drive].fse(folder, "s").isDir
    end,
    getSize = function(path)
      local drive, folder = _findmount(path)
      return mountpoints[drive].fse(folder, "s").size
    end,
    getFreeSpace = function(path)
      local drive, folder = _findmount(path)
      return mountpoints[drive].fse("/", "f")
    end,
    makeDir = function(path)
      local drive, folder = _findmount(path)
      if not mountpoints[drive].fse(ofs.combine(folder, ".."), "s").readOnly then
        mountpoints[drive].fse(folder, "m")
      else
        error(path .. ": Access denied")
      end
    end,
    isReadOnly = _ro,
    move = function(from, to)
      local fdrive, ffolder = _findmount(from)
      local tdrive, tfolder = _findmount(to)
      if _ro(tfolder) then
        error("Move not implemented")
      else
        error(to .. ": Access denied")
      end
    end,
    copy = function(from, to)
      local fdrive, ffolder = _findmount(from)
      local tdrive, tfolder = _findmount(to)
      if _ro(tfolder) then
        local fhandle = _wopen(from, "r")
        local thandle = _wopen(to, "w")
        thandle.write(fhandle.readAll())
        thandle.close()
        fhandle.close()
      else
        error(to .. ": Access denied")
      end
    end,
    open = function(path, mode)
      return _wopen(path, mode)
    end,
    pflist = function(path, rpath, appto)
      local o = appto(rpath)
      for x, _ in pairs(mountpoints) do
        local p = (x .. "/"):match("^/.-/")
        p = p:sub(2, p:len())
        p = p:sub(1, p:len() - 1)
        if x:starts(path) and x ~= "/" and not table.contains(o, p) then
          table.insert(o, p)
        end
      end
      return o
    end
  }
end
