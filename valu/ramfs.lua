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
        elseif mode == "r" then --std open
        elseif mode == "w" then --std open
        elseif mode == "a" then --std open
        elseif mode == "rb" then --std open
        elseif mode == "wb" then --std open
        else error("Invalid mode",4)
        end
    end
end
