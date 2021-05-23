-- Virtual filesystem
return {
    createAPI = function(ofs, kernel)
        local fst = {
            combine = kernel.exportfunc("fs.combine", function (...) 
                local s = ofs.combine(...)
                s = "/" .. s
                return s
            end),
            copy = kernel.exportfunc("fs.copy", function ()
                
            end)
        }
        print(fst.combine("/", "/a/b"))
        return {
            fs = ofs
        } --fst
    end
}