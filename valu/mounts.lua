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
    ["/"] = {isReal = true, realPath = "/ccx/valu", readOnly = false},
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
      return "/", path:gsub("//","/")
    end
    return x, y:gsub("//","/")
  end
  local _wopen = function(path, mode)
    local drive, folder = _findmount(path)
    local stat = mountpoints[drive].fse(folder, "s")
    if mode == "s" then return stat end
    if mode == "r" or mode == "w" or mode == "a" or mode == "rb" or mode == "wb" or mode == "ab" then
      if stat and stat.isDir then error(path .. ": Can't open directory",3) end
      local nmode = mode
      local noByte = false
      if mode == "r" then nmode = "rb" end if mode == "w" then nmode = "wb" end if mode == "a" then nmode = "ab" end if mode == "a" and not stat then nmode = "wb2" end if mode == "w" and not stat then nmode = "wb2" end if mode == "wb" and not stat then nmode = "wb2" end if mode == "ab" and not stat then nmode = "wb2" end
      if mode == "r" or mode == "w" or mode == "a" then noByte = true end
      if mode == "r" or mode == "rb" then
         local ohandle = mountpoints[drive].fse(folder, nmode)
         local size = mountpoints[drive].fse(folder, "s").size
         return {
           close = ohandle.close,
           read = function(n)
            if not n then n = 1 end
            if noByte then
              local out = table.pack(ohandle.read(n))
              for i, a in ipairs(out) do
                out[i] = string.char(a)
              end
              return table.concat(out,"")
            else
              return ohandle.read(n)
            end
           end,
           readAll = function()
            local out = table.pack(ohandle.read(size))
            for i, a in ipairs(out) do
              out[i] = string.char(a)
            end
            out = table.concat(out,"")
            return out
           end,
          readLine = function()
            local out = table.pack(ohandle.read(size))
            for i, a in ipairs(out) do
              out[i] = string.char(a)
            end
            out = table.concat(out)
            return string.split(out,"\n")
           end,
           seek = ohandle.seek
         }
      else
        local ohandle = mountpoints[drive].fse(folder, nmode)
        return {
          close = ohandle.close,
          seek = ohandle.seek,
          write = function(thing)
            if type(thing) == "number" then ohandle.write(thing) elseif type(thing) == "string" then
              for c in thing:gmatch"." do
                ohandle.write(string.byte(c))
              end
            end
          end,
          writeLine = function(thing)
            if type(thing) == "number" then error("writeLine cannot be used with numbers") end
            ohandle.write(thing .. "\n")
          end
        }
      end
    end
    return mountpoints[drive].fse(folder, mode)
  end
  local _ro = function(path)
    local drive, folder = _findmount(path)
    local x = false
    local f = false
    if mountpoints[drive].isReal then
      x = ofs.isReadOnly(mountpoints[drive].realPath)
    else
      local stat = mountpoints[drive].fse(ofs.combine(folder, ".."), "s")
      if stat ~= nil then
        f = stat.readOnly
      end
    end
    return f or mountpoints[drive].readOnly or x
  end
  function _mdir(path)
    local drive, folder = _findmount(path)
    local stat = mountpoints[drive].fse("/" .. ofs.combine(folder, ".."), "s")
    if not stat then 
      _mdir("/" .. ofs.combine(ofs.combine(drive, folder), ".."))
      stat = mountpoints[drive].fse("/" .. ofs.combine(folder, ".."), "s")
    end
    if not stat.readOnly and stat.isDir then
      mountpoints[drive].fse(folder, "m")
    else
      error(path .. ": Access denied")
    end
  end
  function _rdel(drive,folder)
    for _, child in pairs(mountpoints[drive].fse(folder,"l")) do
      if mountpoints[drive].fse("/" .. ofs.combine(folder,child),"s").isDir then _rdel(drive,"/" .. ofs.combine(folder,child)) end
      mountpoints[drive].fse("/" .. ofs.combine(folder,child),"d")
    end
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
      if folder == "/" then error(path .. ": Can't delete filesystem root", 3) end
      local stat = mountpoints[drive].fse(folder, "s")
      if not stat then error(path .. ": File or Folder not found",3) end
      if not mountpoints[drive].fse("/" .. ofs.combine(folder, ".."), "s").readOnly then
        if stat.isDir then
          _rdel(drive, folder)
        end
        mountpoints[drive].fse(folder, "d")
      else
        error(path .. ": Access denied")
      end
    end,
    list = function(path)
      local drive, folder = _findmount(path)
      local stat = mountpoints[drive].fse(folder, "s")
      if not stat then error(path .. ": File or Folder not found",4) end
      if not stat.isDir then error(path .. ": Not a folder",4) end
      return mountpoints[drive].fse(folder, "l")
    end,
    exists = function(path)
      local drive, folder = _findmount(path)
      return mountpoints[drive].fse(folder, "s") ~= nil
    end,
    isDir = function(path)
      local drive, folder = _findmount(path)
      local stat = mountpoints[drive].fse(folder, "s")
      if not stat then return nil end
      return stat.isDir
    end,
    getSize = function(path)
      local drive, folder = _findmount(path)
      local stat = mountpoints[drive].fse(folder, "s")
      if not stat then error(path .. ": File or Folder not found") end
      return stat.size
      
    end,
    getFreeSpace = function(path)
      local drive, folder = _findmount(path)
      if not mountpoints[drive].fse(folder, "s") then error(path .. ": File or Folder not found",3) end
      return mountpoints[drive].fse(folder, "f")
    end,
    getCapacity = function(path)
      local drive, folder = _findmount(path)
      if not mountpoints[drive].fse(folder, "s") then error(path .. ": File or Folder not found",3) end
      return mountpoints[drive].fse(folder, "c")
    end,
    makeDir = _mdir,
    isReadOnly = _ro,
    move = function(from, to)
      local fdrive, ffolder = _findmount(from)
      local tdrive, tfolder = _findmount(to)
      if not mountpoints[fdrive].fse("/" .. ofs.combine(ffolder, ".."), "s") then error(from .. ": File or Folder not found") end
      if not mountpoints[tdrive].fse("/" .. ofs.combine(tfolder, ".."), "s") then error(to .. ": File or Folder not found") end
      if not _ro(tfolder) then
        error("Move not implemented")
      else
        error(to .. ": Access denied")
      end
    end,
    copy = function(from, to, fromReal, toReal)
      local fdrive, ffolder, tdrive, tfolder
      if not fromReal then fdrive, ffolder = _findmount(from) end
      if not toReal then tdrive, tfolder = _findmount(to) end
      if not fromReal then if not mountpoints[fdrive].fse("/" .. ofs.combine(ffolder, ".."), "s") then error(from .. ": File or Folder not found") end else if not ofs.exists(from) then error(from .. ": File or Folder not found") end end
      if not toReal then if not mountpoints[tdrive].fse("/" .. ofs.combine(tfolder, ".."), "s") then error(to .. ": File or Folder not found") end else if not ofs.exists(to) then error(from .. ": File or Folder not found") end end
      if not _ro(tfolder) then
        local fhandle, thandle
        if fromReal then fhandle = ofs.open(from, "rb") else fhandle = _wopen(from, "rb") end
        if toReal then thandle = ofs.open(to, "rb") else thandle = _wopen(to, "wb") end
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
