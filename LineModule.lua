--[[
if typeof(getreg()["linen#storage.count"]) ~= "number" then
    getreg()["linen#storage.count"] = 1
else

	getreg()["linen#storage.count"] += 1
end

local scriptcount = (1 - 1) + getreg()["linen#storage.count"]
local isCount = function()
    return getreg()["linen#storage.count"] == scriptcount
end
]]

-- Written by: reallinens [ on discord.com ]
-- Optimized for performance, can be re-executed as many times as you want

-- V3rmillion Profile: https://v3rm.net/members/linen.418/
-- Version 1.3 [ Fixed for current exploits ]

--[[ Changelogs ->
   1.2 -
   Cache.add returns the first argument passed, example: print(Cache.add(game.Players.PlayerAdded:Connect(function() end))) -- output: RBXscriptsignal

   1.1 -
   Added DeepClone function, basically clones a table giving you the option t modify the output of the clone in the second argument (check out the function)
   NOW YOU HAVE TO MANUALLY CALL Module:Load() to delete, end or stop previous loops, objects or events
]]
local Module = { LuaLoopCount = 0, Cache = {} }
local CustomData = {}

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

setmetatable(CustomData, {
    __index = function(...)
        return rawget(...)
    end,
    __newindex = function(...)
        return rawset(...)
    end,
    __call = function(...) 
        return (...) -- self
    end
})

getreg = getreg or (getreg or debug and debug.getregistry) or function() return CustomData end
getreg = type(getreg)=="function" and getreg or CustomData -- Incase ur exploit is really shitty shitty
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    local create_folder = makefolder or createfolder or newfolder or make_folder or new_folder or create_folder
    local folder_exist = isfolder or is_folder or folderexist or folder_exist
    local new_file = writefile or write_file or newfile or createfile or new_file or create_file
    local file_exist = isfile or doesfileexist or file_exist or fileexist or does_fileexist or does_file_exist
    local read_file = readfile or read_file or read_file_data or readfiledata or readfilebytes or read_file_bytes or readfile_bytes or read_filebytes
    assert(create_folder and folder_exist and new_file and file_exist and read_file and hookmetamethod, "Exploit not supported. [ CreateFolder, FolderExist, Hookmetamethod, newfile, fileexist ]")
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
local WrapFunction = function(func, ...) return type(func)=="function" and coroutine.wrap(func)(...) or false end -- coroutine.wrap without having to use () at the end

-------------------------
--~~~~~~~~~~~~ Safe Functions
function Module:EndObject(object, tb, ind)
    if object then
        pcall(function() object:Destroy() end)
        pcall(function() object:Disconnect() end)
        pcall(function() object:Remove() end)
        pcall(function() object:Close() end)

        return true
    end
    if type(tb)=="table" and ind then
        tb[ind] = nil
    end

    return false
end

Module["L_wait"] = function()
    for i = 1, 5 do 
        task.wait()
        RunService.Heartbeat:Wait()
        RunService.RenderStepped:Wait()
        RunService.PreRender:Wait() 
    end
end

Module["TweenObjects"] = function(tweeninfo, propertyTable, ...)
    local objects = {...}
    propertyTable = type(propertyTable)=="table" and propertyTable or {}
    tweeninfo = typeof(tweeninfo)=="TweenInfo" and tweeninfo or TweenInfo.new(1)
    local Tweens = {}

    for i,v in next, objects do
        pcall(function()
            local Tween = TweenService:Create(v, tweeninfo, propertyTable)
            Tweens[v] = Tween
        end)
    end

    for i,v in next, Tweens do
        v:Play()
    end
    return Tweens
end

Module["DeepClone"] = function(tb, func) -- Deep clones a table
    local result = {}
    func = type(func) == "function" and func or function(...) return ... end
    for i, v in next, tb do
        local _i, _v = i, v
        _i = type(_i) == "table" and Module["DeepClone"](_i, func) or _i
        _v = type(_v) == "table" and Module["DeepClone"](_v, func) or _v
        _i = func(_i) or _i
        _v = func(_v) or _v
        result[_i] = _v
    end
    return result
end

Module["FileExist"] = function(...)
    local suc,err = pcall(read_file, ...)
    return suc and err or false
end

Module["FolderExist"] = function(...)
    local suc,err = pcall(folder_exist, ...)
    return suc and err or false
end

Module["getTableCount"] = function(v)
    if type(v)~="table" then return 0 end
    local count = 0;for i,v in next, v do count+=1 end;return count
end

Module["getInTable"] = function(v, amt: number)
    if type(v)~="table" then return nil end
    amt = type(amt)=="number" and amt or 1
    local count = 0;for i,v in next, v do count+=1;if count==amt then return v, i, amt end end;return nil
end

Module["CheckType"] = function(a, b, c)
    if type(b)~="string" then return c end
    return typeof(a):lower()==b:lower() and a or c
end

Module["isnumber"] = function(str)
    local suc,err = pcall(function()return str/1 end)
    if not suc then return false; end
    return err
end

Module["L_print"] = function(...)
    local tb = {...}
    local doneMessage = ""
    for i = 1, #tb do
        local inst = tb[i]
        local result = "Output Undefined"

        local suc, err = pcall(tostring, inst)
        local _suc, _err = pcall(function()return (typeof(inst)=="Instance" and inst:GetFullName().." | " or "").."type<"..typeof(inst)..">" end)
        if suc then result = err else result = (_suc and _err or result) end

        doneMessage ..= result..(i==#tb and "" or " ")
    end
    return (rconsoleprint or print)("\n"..(type(doneMessage)=="string" and doneMessage or "Output Undefined"))
end

Module["Loop"] = function(func: "Function to run in the loop", seconds: "Each second to loop | 0 = none", yeild: "Wether you want the loop to yeild", ...: "Arguments to pass to the 'func'")
    seconds = type(seconds) == "number" and seconds or nil
    if(type(seconds)=="number" and 0 >= seconds)then seconds = nil end

    func = type(func)=="function" and func or nil
    if not func then return { Stop = function() end, End = function() end}; end

    local WrapFunction = function(func, ...)if type(func)=="function"then coroutine.wrap(func)(...);return(...)end;return false;end
    local breakLoop = false
    local loopDone = true
    --|||||||||||||||
    local function Callback(...)
        if yeild then
            if not loopDone then return; end
        end

        loopDone = false
        local suc, err = pcall(func, ...)
        if not suc and not Module["LoopIgnoreError"] then Module["L_print"]((" [ LuaLoop #%s Bug ]: "..tostring(err)):format(Module.LuaLoopCount)) end
        loopDone = true
    end

    local function mainLoop(...)
        local tim = tick()
        while game:GetService("RunService").Heartbeat:Wait() and getreg().LU_Loaded and not breakLoop do
            if seconds then
                if tick()-tim >= seconds-.1 then
                    tim = tick()
                    Callback(...)
                end
            else
                Callback(...)
            end
        end
    end

    if yeild then
        mainLoop(...)
    else
        WrapFunction(function(...)
            local suc, err = pcall(mainLoop, ...)
            if not suc and not Module["LoopIgnoreError"] then Module["L_print"]((" [ LuaLoop #%s Bug ]: "..tostring(err)):format(Module.LuaLoopCount)) end
        end, ...)
    end
    --|||||||||||||||
    Module.LuaLoopCount += 1
    return {
        Stop = function()
            breakLoop = true
            return true
        end,
        End = function()
            breakLoop = true
            return true
        end
    }
end

--~~~~~~~~~~~~ Table Functions
local table = table
if setreadonly then setreadonly(table, false) else table = Module["DeepClone"](table) end

table.slice = table.slice or function(tbl: {}, first: number, last: number, step: number) -- Works like JavaScripts slice
    local sliced = {}

    pcall(function()
        for i = first or 1, last or #tbl, step or 1 do
            sliced[#sliced+1] = tbl[i]
        end
    end)

    return sliced
end

--~~~~~~~~~~~~ Caching Framework
Module.Cache = {
    add = function(value: any, name: string)
        local GlobalCache = getreg().LU_Loaded or Module
        local cacheName = name or #GlobalCache["Cache"]+1

        GlobalCache["Cache"][cacheName] = value
        return value
    end,

    del = function(name: string)
        local GlobalCache = getreg().LU_Loaded or Module
        local cacheName = name or #GlobalCache["Cache"]+1
    
        Module:EndObject(GlobalCache["Cache"][cacheName], GlobalCache["Cache"], cacheName)    
    end
}

--~~~~~~~~~~~~ Http Functions
Module.Http = {
    GET = function(link)
        if type(link)~="string" then return nil; end
        local suc,err = pcall(function() return game:HttpGet(link) end)
        -- >.< Deku Demz Is Gay  --
        if suc then return err; end
        return nil
    end
}

--~~~~~~~~~~~~ Storage Functions [ Data Saving / Flags ]
Module.Storage = {
    Data = {
        -- This is where Data will be saved / Loaded to
        -- Before accessing this table, please use this once: Module.Storage.Load()
    }, 

    Load = function( baseName, saveEach: number | "How often you want the data to save, Defaults to 1") -- Storage.Load("FolderName") -- [ If folder doesn't exist, it creates ]
        baseName = type(baseName)=="number" and baseName or "LinenModule"
        saveEach = type(saveEach)=="number" and saveEach or 1

        if not Module.FolderExist(baseName) then create_folder(baseName) end
        baseName ..= "/"..tostring(game.PlaceId)..".txt"

        if not Module.FileExist(baseName) then new_file(baseName, "{}") end
        local CharData = Module.FileExist(baseName) or "{}"

        local isdecodeable = pcall(function() CharData = HttpService:JSONDecode(CharData) end)
        if not isdecodeable then CharData = {}; new_file(baseName, "{}") end

        if type(Module.Storage)=="table" then

            if type(Module.Storage["Data"])~="table" then
                Module.Storage["Data"] = {}
            end

            if Module.Storage["FlagsLoaded"] then
                return; -- Incase you used Module.Storage.Load twice on accident
            end

            Module.Storage["Data"] = type(CharData)=="table" and CharData or {}
            Module.Storage["FlagsLoaded"] = true

        end

        WrapFunction(function() -- Basically how the data saves
            if httpget then -- celery detected?!?!
                warn("Cant save file on celery, causes lag. But you can manually write the new options ur self.")
                pcall(new_file, baseName, "{}")
                return;
            end

            Module["Loop"](function()
                local JsonPassed, JsonToString = pcall(function()
                    return HttpService:JSONEncode(Module.Storage["Data"])
                end)

                if JsonPassed and type(JsonToString)=="string" and Module.FileExist(baseName) then
                    pcall(new_file, baseName, JsonToString)
                end
            end, saveEach)
        end)
    end
}


--
function Module:Load(force) 
    if not force and Module.Loaded then return; end -- If you want to re-load the module for some reason [ not recommended ]

    if type(getreg().LU_Loaded) == "table" then
        for i, ev in next, getreg().LU_Loaded["Cache"] do
            pcall(function() ev:Destroy() end)
            pcall(function() ev:Disconnect() end)
            pcall(function() ev:Remove() end)
            pcall(function() ev:Close() end)
        end
    end

    getreg().LU_Loaded = false

    for i = 1, 5 do 
        task.wait()
        RunService.Heartbeat:Wait()
        RunService.RenderStepped:Wait()
        RunService.PreRender:Wait() 
    end

    getreg().LU_Loaded = { startTime = tick(), Events = {}, Cache = {} }
    if Module["getTableCount"](Module["Cache"]) > 0 then
        for i,v in next, Module["Cache"] do
            --add old acche
            getreg().LU_Loaded["Cache"][i]= v
        end
        Module["Cache"] = {}
    end
    return getreg().LU_Loaded 

end
--
getreg().LinenModule = Module
return Module

--[[ Usage Example:

local LinenModule: { L_print: "function( ... )", Loop: "function( func, seconds, yeild, ... )" } = loadstring(game:HttpGet("https://reallinen.github.io/Files/Scripts/LinenModule.lua"))()
local Storage: { Data: {}, Load: "function( folder_name: string )" }, Http: { GET: "function( link: string )" }, Cache: { add: "function( name: string, object: anything/dynamic )", del: "function( name: string )" } = LinenModule["Storage"], LinenModule["Http"], LinenModule["Cache"]
   
for i,v in next, LinenModule do
    if i=="print" then continue; end
    getreg()[i] = v
end
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print(Loop, L_print, FileExist, FolderExist, CheckType, Storage) -- function, function, function, function, function, { Data: {}, Load: function }

]]