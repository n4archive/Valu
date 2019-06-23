if _HOST then howlci.log("info", "Host: " .. _HOST) end
if _CC_VERSION then howlci.log("info", "CC Version" .. _CC_VERSION) end
if _MC_VERSION then howlci.log("info", "MC Version" .. _MC_VERSION) end
if _LUAJ_VERSION then howlci.log("info", "LuaJ Version " .. _LUAJ_VERSION) end

shell.run("pastebin","run","LYAxmSby","get","703e2f46ce68c2ca158673ff0ec4208c/Howl.min.lua","Howl")
local handle = fs.open(".howl/settings.lua", "w")
handle.write('{githubKey='+howlci.getEnv("GHKEY")+'}')
handle.close()

local ok, msg = pcall(shell.run, "Howl", "-v", "upload")
if not ok then
	howlci.status("fail", "Failed running task: " .. (msg or "<no msg>"))
else
	howlci.status("ok", "Everything built correctly!")
end

sleep(2)
howlci.close()
