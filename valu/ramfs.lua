return function()
    local ram = {}
    return function(file,mode)
        print(file)
        print(mode)
        sleep(10)
    end
end