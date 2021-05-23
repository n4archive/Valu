local log_syscall = true
return {
    exportfunc = function(n, a)
        if (log_syscall) then
            return function(...)
                print("SYSCALL:", n .. "(" .. table.concat(table.pack(...), ", ") .. ")")
                return a(...)
            end
        else
            return a
        end
    end
}