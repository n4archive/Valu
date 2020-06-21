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
        -- r, w and a are handled automatically, you only need the byte variants
        elseif mode == "rb" then --std open
            local handle = {pos = 0, file_table = ram[file].contents}
            local fandle = {}
            function fandle.close()
                if not handle then error("Attempted to close closed handle",1) end
                handle = nil
            end
            function fandle.read()
                if not handle then error("Attempted to use closed handle",1) end
                handle.pos = handle.pos + 1
                return handle.file_table[handle.pos]
            end
            return fandle
        elseif mode == "wb" then --std open
	    	ram[file] = {desc={readOnly=false,isDir=false,size=0},contents={}}
            local handle = {pos = 0, file_table = ram[file].contents}
            local fandle = {}
            function fandle.close()
                -- flush gets called before close automatically
                if not handle then error("Attempted to close closed handle",1) end
                handle = nil
            end
            function fandle.write(f)
                if not handle then error("Attempted to use closed handle",1) end
                handle.pos = handle.pos + 1
                table.insert(handle.file_table,handle.pos,f)
            end
            function fandle.flush()
                ram[file].desc.size = #(ram[file].contents)
            end
            return fandle
        elseif mode == "wb2" then --wb but for a new file
	    	ram[file] = {desc={readOnly=false,isDir=false,size=0},contents={}}
            table.insert(ram["/" .. fs.getDir(file)].children,fs.getName(file))
            local handle = {pos = 0, file_table = ram[file].contents}
            local fandle = {}
            function fandle.close()
                -- flush gets called before close automatically
                if not handle then error("Attempted to close closed handle",1) end
                handle = nil
            end
            function fandle.write(f)
                if not handle then error("Attempted to use closed handle",1) end
                handle.pos = handle.pos + 1
                table.insert(handle.file_table,handle.pos,f)
            end
            function fandle.flush()
                ram[file].desc.size = #(ram[file].contents)
            end
            return fandle
        elseif mode == "ab" then --std open
            local handle = {pos = #(ram[file].contents), file_table = ram[file].contents}
            local fandle = {}
            function fandle.close()
                -- flush gets called before close automatically
                if not handle then error("Attempted to close closed handle",1) end
                handle = nil
            end
            function fandle.write(f)
                if not handle then error("Attempted to use closed handle",1) end
                handle.pos = handle.pos + 1
                table.insert(handle.file_table,handle.pos,f)
            end
            function fandle.flush()
                ram[file].desc.size = #(ram[file].contents)
            end
            return fandle
        else error("Invalid mode",4)
        end
    end
end
