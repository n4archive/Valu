return function()
    -- If you wonder where are the safety checks, the delete recursion, etc: They are inside Valu. The fs only has to handle fs things.
    local ram = {["/"]={desc={readOnly=false,isDir=true,size=0},children={}}}
    return function(file,mode)
        if mode == "s" then --stat
		    if not ram[file] then return nil end
	    	return ram[file].desc
        elseif mode == "l" then --ls
	    	return ram[file].children
	    elseif mode == "f" then --free space
            return 999999
        elseif mode == "c" then --capacity
            return 9999999
        elseif mode == "m" then --mkdir
	    	ram[file] = {desc={readOnly=false,isDir=true,size=0},children={}}
            table.insert(ram["/" .. fs.getDir(file)].children,fs.getName(file))
        elseif mode == "d" then --delete
            local file_root = "/" .. fs.combine(file, "..")
            local index={}
            for k,v in pairs(ram[file_root].children) do
                index[v]=k
            end
            table.remove(ram[file_root].children,index[fs.getName(file)])
            ram[file] = nil
        -- r, w and a are handled automatically, you only need the byte variants, and them only in minimal
        elseif mode == "rb" then --std open
            local handle = {pos = 0, file_table = ram[file].contents}
            local fandle = {}
            function fandle.close()
                if not handle then error("Attempted to close closed handle",1) end
                handle = nil
            end
            function fandle.read(n)
                if not handle then error("Attempted to use closed handle",1) end
                handle.pos = handle.pos + n
                return table.unpack(handle.file_table,handle.pos-n,n)
            end
            function fandle.seek(whence, offset)
                if not offset then offset = 0 end
                if not whence then whence = "cur" end
                if whence == "cur" then handle.pos = handle.pos + offset end
                if whence == "set" then handle.pos = 0 + offset end
                if whence == "end" then handle.pos = handle.file_table.desc.size + offset end
            end
            return fandle
        elseif mode == "wb" or mode == "wb2" then --std open (wb2 for nonexistent files)
            ram[file] = {desc={readOnly=false,isDir=false,size=0},contents={}}
            if mode == "wb2" then table.insert(ram["/" .. fs.getDir(file)].children,fs.getName(file)) end
            local handle = {pos = 0, file_table = ram[file].contents}
            local fandle = {}
            function fandle.close()
                if not handle then error("Attempted to close closed handle",1) end
                fandle.flush()
                handle = nil
            end
            function fandle.write(f)
                if not handle then error("Attempted to use closed handle",1) end
                handle.pos = handle.pos + 1
                table.insert(handle.file_table,handle.pos,f)
            end
            function fandle.flush()
                if not handle then error("Attempted to use closed handle",1) end
                ram[file].desc.size = #(ram[file].contents)
            end
            function fandle.seek(whence, offset)
                if not offset then offset = 0 end
                if not whence then whence = "cur" end
                if whence == "cur" then handle.pos = handle.pos + offset end
                if whence == "set" then handle.pos = 0 + offset end
                if whence == "end" then fandle.flush() handle.pos = handle.file_table.desc.size + offset end
            end
            return fandle
        elseif mode == "ab" then --std open
            local handle = {pos = #(ram[file].contents), file_table = ram[file].contents}
            local fandle = {}
            function fandle.close()
                if not handle then error("Attempted to close closed handle",1) end
                fandle.flush()
                handle = nil
            end
            function fandle.write(f)
                if not handle then error("Attempted to use closed handle",1) end
                handle.pos = handle.pos + 1
                table.insert(handle.file_table,handle.pos,f)
            end
            function fandle.flush()
                if not handle then error("Attempted to use closed handle",1) end
                ram[file].desc.size = #(ram[file].contents)
            end
            function fandle.seek(whence, offset)
                if not offset then offset = 0 end
                if not whence then whence = "cur" end
                if whence == "cur" then handle.pos = handle.pos + offset end
                if whence == "set" then handle.pos = 0 + offset end
                if whence == "end" then fandle.flush() handle.pos = handle.file_table.desc.size + offset end
            end
            return fandle
        else error("Invalid mode",4)
        end
    end
end
