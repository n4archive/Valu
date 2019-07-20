return function()
    local ram = {["/"]={desc={readOnly=false,isDir=true,size=0}}}
    return function(file,mode)
        if mode == "s" then
            return ram[file].desc --stat
        elseif mode == "l" then --ls
        elseif mode == "f" then --free space
        elseif mode == "m" then --mkdir
        elseif mode == "r" then --std open
        elseif mode == "w" then --std open
        elseif mode == "a" then --std open
        elseif mode == "rb" then --std open
        elseif mode == "wb" then --std open
        else error("Invalid mode")
        end
    end
end