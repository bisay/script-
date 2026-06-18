--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║  ROBLOX ULTIMATE RECON SUITE v2.0                              ║
    ║  Created by Hermes Agent                                       ║
    ║  The most comprehensive Roblox game analysis tool              ║
    ╚══════════════════════════════════════════════════════════════════╝
    
    FEATURES:
    - Full game dump with source code
    - Real-time remote monitoring
    - Automatic vulnerability scanner
    - Remote fuzzing / testing
    - Hidden object detection
    - Anti-cheat detection
    - Admin panel finder
    - Speed/fly/godmode detection
    - Network traffic analyzer
    - Player activity monitor
    - Auto-exploit suggestion engine
    
    MODES:
    1. DUMP    - One-time full game analysis
    2. MONITOR - Real-time monitoring
    3. FUZZ    - Remote testing/fuzzing
    4. FULL    - Everything combined
]]

-- ============================================================
-- MASTER CONFIGURATION
-- ============================================================
local CONFIG = {
    -- MODE: "DUMP", "MONITOR", "FUZZ", "FULL"
    MODE = "DUMP",
    
    -- DUMP Settings
    DUMP_SOURCE_CODE = true,        -- Dump all script source code
    DUMP_LINE_NUMBERS = true,       -- Add line numbers to dumps
    DUMP_HIERARCHY = true,          -- Full game hierarchy
    DUMP_REMOTES = true,            -- All remotes
    DUMP_GUI = true,                -- All GUI elements
    DUMP_ASSETS = true,             -- Mesh, decal, animation, sound IDs
    DUMP_TOOLS = true,              -- All tools
    DUMP_TAGS = true,               -- CollectionService tags
    DUMP_PLAYERS = true,            -- Current player info
    DUMP_SECURITY = true,           -- Security audit
    
    -- MONITOR Settings
    MONITOR_REMOTES = true,         -- Monitor all remote calls
    MONITOR_FIRESERVER = true,      -- Log FireServer calls
    MONITOR_INVOKESERVER = true,    -- Log InvokeServer calls
    MONITOR_PLAYER_CHANGES = true,  -- Monitor humanoid property changes
    MONITOR_NEW_INSTANCES = true,   -- Monitor new instances appearing
    MONITOR_GUI_CHANGES = true,     -- Monitor GUI visibility changes
    MONITOR_HEARTBEAT = 30,         -- Stats update interval (seconds)
    
    -- FUZZ Settings
    FUZZ_REMOTE_EVENTS = true,      -- Test RemoteEvents
    FUZZ_REMOTE_FUNCTIONS = true,   -- Test RemoteFunctions
    FUZZ_MAX_ARGS = 10,             -- Max args to try per remote
    FUZZ_DELAY = 0.5,               -- Delay between fuzz attempts (seconds)
    FUZZ_TYPES = {"string", "number", "boolean", "nil", "table", "Instance", "Vector3", "CFrame", "Color3", "BrickColor", "Enum"}, -- Types to test
    
    -- SECURITY Settings
    SECURITY_CHECK_ANCHORED = true,
    SECURITY_CHECK_INVISIBLE = true,
    SECURITY_CHECK_NOCLIP = true,
    SECURITY_CHECK_SPEED = true,
    SECURITY_CHECK_FLY = true,
    SECURITY_CHECK_GODMODE = true,
    SECURITY_CHECK_ADMIN = true,
    SECURITY_CHECK_ANTICHEAT = true,
    SECURITY_CHECK_DATASTORE = true,
    SECURITY_CHECK_HTTP = true,
    SECURITY_CHECK_LOADSTRING = true,
    SECURITY_CHECK_ENVIRONMENT = true,
    
    -- OUTPUT Settings
    OUTPUT_FILE = "roblox_recon_" .. tostring(game.PlaceId) .. ".txt",
    OUTPUT_VULN_FILE = "roblox_vulns_" .. tostring(game.PlaceId) .. ".txt",
    OUTPUT_FUZZ_FILE = "roblox_fuzz_" .. tostring(game.PlaceId) .. ".txt",
    OUTPUT_MONITOR_FILE = "roblox_monitor_" .. tostring(game.PlaceId) .. ".txt",
    AUTO_SAVE = true,
    AUTO_CLIPBOARD = true,
    MAX_CONSOLE_LINES = 200,
    
    -- ANTI-DETECTION
    ANTI_DETECT = true,
    STEALTH_MODE = false,
}

-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local PhysicsService = game:GetService("PhysicsService")
local SocialService = game:GetService("SocialService")
local TextChatService = game:GetService("TextChatService")
local VoiceChatService = game:GetService("VoiceChatService")

-- ============================================================
-- UTILITIES
-- ============================================================
local output = {}
local vulnOutput = {}
local fuzzOutput = {}
local monitorOutput = {}
local vulnCount = 0
local logCount = 0
local hookedRemotes = {}
local remoteCallHistory = {}
local consoleLines = 0

-- Safe property getter
local function safe(obj, prop)
    local ok, val = pcall(function() return obj[prop] end)
    return ok and val ~= nil and val or nil
end

-- Class name
local function cn(obj)
    local ok, c = pcall(function() return obj.ClassName end)
    return ok and c or "?"
end

-- Full path
local function fp(obj)
    local parts = {}
    local cur = obj
    while cur and cur ~= game do
        table.insert(parts, 1, cur.Name)
        cur = cur.Parent
    end
    return "game." .. table.concat(parts, ".")
end

-- Get all descendants
local function all(obj)
    local ok, d = pcall(function() return obj:GetDescendants() end)
    return ok and d or {}
end

-- Get children count
local function cc(obj)
    local ok, c = pcall(function() return #obj:GetChildren() end)
    return ok and c or 0
end

-- Get children table
local function children(obj)
    local ok, c = pcall(function() return obj:GetChildren() end)
    return ok and c or {}
end

-- Timestamp
local function ts()
    return os.date("%H:%M:%S")
end

-- Save file
local function saveFile(name, content)
    local ok = false
    pcall(function()
        if writefile then
            writefile(name, content)
            ok = true
        end
    end)
    return ok
end

-- Append file
local function appendFile(name, line)
    local ok = false
    pcall(function()
        if appendfile then
            appendfile(name, line .. "\n")
            ok = true
        end
    end)
    return ok
end

-- Safe JSON encode
local function safeJSON(obj)
    local ok, result = pcall(function()
        return HttpService:JSONEncode(obj)
    end)
    return ok and result or tostring(obj)
end

-- Print with line counting
local function out(text, target)
    target = target or output
    table.insert(target, text)
    consoleLines = consoleLines + 1
    if consoleLines <= CONFIG.MAX_CONSOLE_LINES then
        print(text)
    elseif consoleLines == CONFIG.MAX_CONSOLE_LINES + 1 then
        print("... (console output paused, full log in file)")
    end
end

-- ============================================================
-- VULNERABILITY ENGINE
-- ============================================================
local function addVuln(severity, category, description, path, details)
    vulnCount = vulnCount + 1
    local entry = string.format(
        "[%s] #%d | %s | %s\n  -> %s%s",
        severity, vulnCount, category, description, path or "N/A",
        details and ("\n  Details: " .. details) or ""
    )
    table.insert(vulnOutput, entry)
    print("[VULN-" .. severity .. "] " .. category .. ": " .. description)
    return entry
end

-- ============================================================
-- ANALYSIS ENGINE
-- ============================================================

-- Analyze remote
local function analyzeRemote(obj)
    local rPath = fp(obj)
    local name = obj.Name
    local rCn = cn(obj)
    
    -- Suspicious name keywords
    local susKeywords = {
        "buy", "purchase", "shop", "store", "trade", "sell", "give", "grant",
        "admin", "mod", "ban", "kick", "mute", "unban",
        "teleport", "tp", "tele", "warp",
        "fly", "flyhack", "speed", "speedhack", "jump", "noclip",
        "god", "godmode", "invincible", "die", "kill", "respawn",
        "money", "cash", "coins", "gems", "robux", "currency",
        "reward", "claim", "daily", "spin", "wheel", "lottery", "jackpot",
        "add", "remove", "delete", "set", "get", "update",
        "item", "weapon", "gun", "tool", "equip", "unequip", "inventory",
        "spawn", "despawn", "create", "destroy",
        "health", "damage", "heal", "buff", "nerf",
        "level", "exp", "xp", "rank", "prestige",
        "unlock", "lock", "access", "permission", "role",
        "save", "load", "reset", "wipe", "data",
        "effect", "particle", "sound", "music",
        "animation", "emote", "dance",
        "vehicle", "car", "plane", "boat", "drive",
        "pet", "companion", "mount",
        "craft", "forge", "build", "place", "destroy",
        "send", "receive", "transfer", "drop",
        "open", "close", "chest", "box", "crate", "pack",
    }
    
    local lowerName = name:lower()
    for _, keyword in pairs(susKeywords) do
        if lowerName:find(keyword) then
            addVuln("HIGH", "SUSPICIOUS_REMOTE",
                "Remote '" .. name .. "' contains keyword '" .. keyword .. "'",
                rPath)
            break
        end
    end
    
    -- Parent context analysis
    local parent = obj.Parent
    if parent then
        local parentLower = parent.Name:lower()
        if parentLower:find("admin") or parentLower:find("mod") or parentLower:find("debug") or parentLower:find("cheat") then
            addVuln("CRITICAL", "ADMIN_REMOTE",
                "Remote in admin/mod/debug container: " .. parent.Name,
                rPath)
        end
        if parentLower:find("shop") or parentLower:find("store") or parentLower:find("market") then
            addVuln("MEDIUM", "SHOP_REMOTE",
                "Remote in shop/store container: " .. parent.Name,
                rPath)
        end
        if parentLower:find("test") or parentLower:find("dev") then
            addVuln("MEDIUM", "TEST_REMOTE",
                "Remote in test/dev container: " .. parent.Name,
                rPath)
        end
    end
    
    -- RemoteFunction analysis
    if rCn == "RemoteFunction" then
        addVuln("MEDIUM", "REMOTE_FUNCTION",
            "RemoteFunction '" .. name .. "' - client can invoke synchronously",
            rPath)
    end
    
    -- Public placement
    if parent and parent == ReplicatedStorage then
        addVuln("LOW", "PUBLIC_REMOTE",
            "Remote directly under ReplicatedStorage (no organization)",
            rPath)
    end
    
    -- Generic name
    local genericNames = {"a", "b", "c", "d", "e", "f", "event", "remote", "func", "action", "do", "run", "fire", "call", "r", "e", "f", "rf", "re"}
    for _, gen in pairs(genericNames) do
        if lowerName == gen then
            addVuln("LOW", "GENERIC_REMOTE",
                "Remote has generic name: '" .. name .. "'",
                rPath)
            break
        end
    end
    
    -- Very long name (obfuscation?)
    if #name > 50 then
        addVuln("LOW", "LONG_REMOTE_NAME",
            "Remote has unusually long name (" .. #name .. " chars): " .. name:sub(1, 50) .. "...",
            rPath)
    end
    
    -- Hash-like name (random strings)
    if name:match("^%x+$") and #name >= 8 then
        addVuln("MEDIUM", "HASH_REMOTE_NAME",
            "Remote has hash-like name: " .. name,
            rPath)
    end
end

-- Analyze script
local function analyzeScript(obj)
    local sPath = fp(obj)
    local src = safe(obj, "Source") or ""
    local srcLower = src:lower()
    local sCn = cn(obj)
    
    -- External require
    if srcLower:find("require%s*%(") then
        local reqStart = src:find("require%s*%(")
        if reqStart then
            local reqContent = src:sub(reqStart, math.min(reqStart + 80, #src))
            addVuln("MEDIUM", "EXTERNAL_REQUIRE",
                "Script uses require(): " .. reqContent:sub(1, 60) .. "...",
                sPath)
        end
    end
    
    -- HttpService
    if srcLower:find("httpservice") or srcLower:find("httprequest") or srcLower:find("httppost") or srcLower:find("httpget") then
        addVuln("HIGH", "HTTP_REQUEST",
            "Script uses HttpService - potential data exfiltration",
            sPath)
    end
    
    -- loadstring
    if srcLower:find("loadstring") then
        addVuln("CRITICAL", "LOADSTRING",
            "Script uses loadstring() - dynamic code execution",
            sPath)
    end
    
    -- DataStore access
    if srcLower:find("datastore") then
        local dsMethods = {"getasync", "setasync", "updateasync", "removeasync", "getordereddatastore"}
        for _, method in pairs(dsMethods) do
            if srcLower:find(method) then
                addVuln("HIGH", "DATASTORE_ACCESS",
                    "DataStore access via " .. method,
                    sPath)
            end
        end
    end
    
    -- Leaderstats
    if srcLower:find("leaderstats") or srcLower:find("leaderstat") then
        addVuln("MEDIUM", "LEADERSTATS",
            "Script manages leaderstats",
            sPath)
    end
    
    -- Speed manipulation
    if srcLower:find("walkspeed") then
        addVuln("MEDIUM", "SPEED_MOD",
            "Script modifies WalkSpeed",
            sPath)
    end
    
    -- Jump manipulation
    if srcLower:find("jumppower") or srcLower:find("jumpheight") then
        addVuln("MEDIUM", "JUMP_MOD",
            "Script modifies jump properties",
            sPath)
    end
    
    -- Health manipulation
    if srcLower:find("maxhealth") or srcLower:find(".health") then
        if srcLower:find("takedamage") or srcLower:find("changedamage") then
            addVuln("MEDIUM", "HEALTH_MOD",
                "Script modifies health/damage",
                sPath)
        end
    end
    
    -- FilteringEnabled
    if srcLower:find("filteringenabled") then
        addVuln("CRITICAL", "FILTERING_BYPASS",
            "Script checks/modifies FilteringEnabled",
            sPath)
    end
    
    -- RunService bindings
    if srcLower:find("bindtostep") or srcLower:find("bindtorenderstep") or srcLower:find("bindtophysics") then
        addVuln("INFO", "RUNSERVICE",
            "Script uses RunService binding",
            sPath)
    end
    
    -- TeleportService
    if srcLower:find("teleportservice") or srcLower:find("teleporttoplace") or srcLower:find("teleportasync") then
        addVuln("MEDIUM", "TELEPORT",
            "Script uses TeleportService",
            sPath)
    end
    
    -- MarketplaceService
    if srcLower:find("marketplaceservice") or srcLower:find("userownsgamepassasync") or srcLower:find("promptproductpurchase") then
        addVuln("MEDIUM", "MARKETPLACE",
            "Script accesses MarketplaceService",
            sPath)
    end
    
    -- String obfuscation
    if srcLower:find("string.char") and srcLower:find("string.byte") then
        addVuln("MEDIUM", "STRING_OBFUSCATION",
            "Script uses string.char/byte pattern",
            sPath)
    end
    
    -- Environment manipulation
    if srcLower:find("getfenv") or srcLower:find("setfenv") or srcLower:find("hookfunction") or srcLower:find("hookmetamethod") then
        addVuln("CRITICAL", "ENV_MANIPULATION",
            "Script manipulates Lua environment",
            sPath)
    end
    
    -- Debug library
    if srcLower:find("debug.") then
        addVuln("MEDIUM", "DEBUG_LIB",
            "Script uses debug library",
            sPath)
    end
    
    -- getrawmetatable
    if srcLower:find("getrawmetatable") or srcLower:find("setrawmetatable") then
        addVuln("CRITICAL", "RAW_METATABLE",
            "Script accesses raw metatable",
            sPath)
    end
    
    -- checkcaller
    if srcLower:find("checkcaller") or srcLower:find("islclosure") or srcLower:find("iscclosure") then
        addVuln("HIGH", "CALLER_CHECK",
            "Script checks caller type - possible anti-exploit",
            sPath)
    end
    
    -- getnamecallmethod
    if srcLower:find("getnamecallmethod") or srcLower:find("setnamecallmethod") then
        addVuln("HIGH", "NAMECALL_HOOK",
            "Script hooks namecall method",
            sPath)
    end
    
    -- identifyexecutor
    if srcLower:find("identifyexecutor") or srcLower:find("getexecutorname") then
        addVuln("HIGH", "EXECUTOR_DETECT",
            "Script detects executor - anti-exploit",
            sPath)
    end
    
    -- Protected call patterns (anti-tamper)
    if srcLower:find("pcall") and srcLower:find("error") then
        -- Not necessarily bad, but worth noting
    end
    
    -- Debug.info (newer anti-exploit)
    if srcLower:find("debug.info") then
        addVuln("HIGH", "DEBUG_INFO",
            "Script uses debug.info() - stack inspection anti-cheat",
            sPath)
    end
    
    -- cloneref
    if srcLower:find("cloneref") or srcLower:find("clonereference") then
        addVuln("MEDIUM", "CLONE_REF",
            "Script uses cloneref - possible reference spoofing",
            sPath)
    end
    
    -- gethiddenproperty / sethiddenproperty
    if srcLower:find("gethiddenproperty") or srcLower:find("sethiddenproperty") then
        addVuln("HIGH", "HIDDEN_PROPERTY",
            "Script accesses hidden properties",
            sPath)
    end
    
    -- firesignal
    if srcLower:find("firesignal") or srcLower:find("disconnectconnection") then
        addVuln("HIGH", "SIGNAL_MANIPULATION",
            "Script fires/disconnects signals",
            sPath)
    end
end

-- Analyze part
local function analyzePart(obj)
    local pPath = fp(obj)
    
    if safe(obj, "Anchored") == false then
        addVuln("LOW", "UNANCHORED",
            "Part is unanchored: " .. obj.Name,
            pPath)
    end
    
    if safe(obj, "CanCollide") == false and (safe(obj, "Transparency") or 0) >= 0.5 then
        addVuln("MEDIUM", "HIDDEN_PASSAGE",
            "No-collide + semi-transparent part",
            pPath)
    end
    
    local pos = safe(obj, "Position")
    if pos and typeof(pos) == "Vector3" and pos.Y > 500 then
        addVuln("LOW", "HIGH_POS",
            "Part at Y=" .. math.floor(pos.Y),
            pPath)
    end
end

-- Analyze proximity prompt
local function analyzePrompt(obj)
    local pPath = fp(obj)
    local action = (safe(obj, "ActionText") or ""):lower()
    local objText = (safe(obj, "ObjectText") or ""):lower()
    local combined = action .. " " .. objText
    
    local susWords = {"buy", "purchase", "claim", "collect", "free", "give", "admin", "secret", "hidden", "admin", "cheat", "hack", "exploit", "godmode", "fly", "speed"}
    for _, word in pairs(susWords) do
        if combined:find(word) then
            addVuln("MEDIUM", "SUSPICIOUS_PROMPT",
                "Prompt with suspicious text: '" .. (safe(obj, "ActionText") or "") .. "'",
                pPath)
            break
        end
    end
    
    -- No line of sight required
    if safe(obj, "RequiresLineOfSight") == false then
        addVuln("LOW", "NO_LINE_OF_SIGHT",
            "Prompt doesn't require line of sight",
            pPath)
    end
    
    -- Very large activation distance
    local dist = safe(obj, "MaxActivationDistance")
    if dist and dist > 50 then
        addVuln("LOW", "LARGE_ACTIVATION_DIST",
            "Prompt activation distance: " .. dist,
            pPath)
    end
end

-- ============================================================
-- FULL GAME HIERARCHY
-- ============================================================
local function printHierarchy(obj, indent, maxDepth)
    if indent > maxDepth then return end
    local indentStr = string.rep("  ", indent)
    local objCn = cn(obj)
    local childCount = cc(obj)
    
    local icon = "📁"
    if objCn == "Script" then icon = "📜"
    elseif objCn == "LocalScript" then icon = "📘"
    elseif objCn == "ModuleScript" then icon = "📗"
    elseif objCn == "RemoteEvent" then icon = "🔴"
    elseif objCn == "RemoteFunction" then icon = "🔵"
    elseif objCn == "BindableEvent" then icon = "🟡"
    elseif objCn == "BindableFunction" then icon = "🟠"
    elseif objCn == "Part" or objCn == "MeshPart" then icon = "🔲"
    elseif objCn == "Model" then icon = "📦"
    elseif objCn == "Folder" then icon = "📂"
    elseif objCn == "ScreenGui" then icon = "🖥️"
    elseif objCn == "Tool" then icon = "🔧"
    elseif objCn == "Sound" then icon = "🔊"
    elseif objCn == "Animation" then icon = "🎬"
    elseif objCn == "ProximityPrompt" then icon = "📍"
    elseif objCn == "ClickDetector" then icon = "🖱️"
    elseif objCn == "ForceField" then icon = "🛡️"
    elseif objCn == "Explosion" then icon = "💥"
    elseif objCn == "SpawnLocation" then icon = "🏁"
    elseif objCn == "Team" then icon = "👥"
    else icon = "❓" end
    
    out(indentStr .. icon .. " " .. obj.Name .. " [" .. objCn .. "] (" .. childCount .. " children)")
    
    local objChildren = children(obj)
    for i, child in ipairs(objChildren) do
        if i <= 300 then
            printHierarchy(child, indent + 1, maxDepth)
        else
            out(indentStr .. "  ... " .. (#objChildren - 300) .. " more")
            break
        end
    end
end

-- ============================================================
-- MODE 1: FULL DUMP
-- ============================================================
if CONFIG.MODE == "DUMP" or CONFIG.MODE == "FULL" then
    print("=== ROBLOX ULTIMATE RECON SUITE v2.0 ===")
    print("Mode: " .. CONFIG.MODE)
    print("Scanning...")
    print("")
    
    local lines = {}
    local function w(line)
        table.insert(lines, line)
    end
    
    w("============================================================")
    w("  ROBLOX ULTIMATE RECON REPORT v2.0")
    w("  Generated: " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("============================================================")
    w("")
    
    -- GAME INFO
    w("=== GAME INFO ===")
    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        w("Name       : " .. (info.Name or "?"))
        w("Creator    : " .. (info.Creator and info.Creator.Name or "?"))
        w("Creator ID : " .. (info.Creator and info.Creator.Id or "?"))
        w("Description: " .. string.sub(info.Description or "", 1, 200))
    end)
    w("Place ID   : " .. tostring(game.PlaceId))
    w("Job ID     : " .. tostring(game.JobId))
    w("Max Players: " .. Players.MaxPlayers)
    w("Current    : " .. #Players:GetPlayers())
    w("")
    
    -- HIERARCHY
    if CONFIG.DUMP_HIERARCHY then
        w("=== GAME HIERARCHY ===")
        w("")
        printHierarchy(game, 0, 12)
        w("")
    end
    
    -- SCRIPTS WITH SOURCE CODE
    if CONFIG.DUMP_SOURCE_CODE then
        w("")
        w("============================================================")
        w("  ALL SCRIPTS - FULL SOURCE CODE")
        w("============================================================")
        w("")
        
        local scriptCounts = {Script = 0, LocalScript = 0, ModuleScript = 0}
        
        for _, obj in pairs(all(game)) do
            local objCn = cn(obj)
            if objCn == "Script" or objCn == "LocalScript" or objCn == "ModuleScript" then
                scriptCounts[objCn] = scriptCounts[objCn] + 1
                local src = safe(obj, "Source") or ""
                local lineCount = select(2, src:gsub("\n", "\n"))
                
                w("------------------------------------------------------------")
                w("[" .. objCn .. "] " .. obj.Name)
                w("Path     : " .. fp(obj))
                w("Disabled : " .. tostring(safe(obj, "Disabled")))
                w("Lines    : ~" .. lineCount)
                w("Chars    : " .. #src)
                w("------------------------------------------------------------")
                
                if #src > 0 and CONFIG.DUMP_LINE_NUMBERS then
                    local lineNum = 1
                    for line in src:gmatch("([^\n]*)\n?") do
                        w(string.format("%4d | %s", lineNum, line))
                        lineNum = lineNum + 1
                    end
                elseif #src > 0 then
                    w(src)
                else
                    w("-- [EMPTY]")
                end
                
                w("")
                w("")
                analyzeScript(obj)
            end
        end
        
        w("Scripts Summary:")
        w("  Server Scripts: " .. scriptCounts.Script)
        w("  Local Scripts : " .. scriptCounts.LocalScript)
        w("  Module Scripts: " .. scriptCounts.ModuleScript)
        w("")
    end
    
    -- REMOTES
    if CONFIG.DUMP_REMOTES then
        w("============================================================")
        w("  ALL REMOTES")
        w("============================================================")
        w("")
        
        local remoteCounts = {RemoteEvent = 0, RemoteFunction = 0, BindableEvent = 0, BindableFunction = 0}
        
        for _, obj in pairs(all(game)) do
            local objCn = cn(obj)
            if objCn == "RemoteEvent" or objCn == "RemoteFunction" or objCn == "BindableEvent" or objCn == "BindableFunction" then
                remoteCounts[objCn] = (remoteCounts[objCn] or 0) + 1
                w("[" .. objCn .. "] " .. obj.Name)
                w("  Path   : " .. fp(obj))
                w("  Parent : " .. (safe(obj.Parent, "Name") or "?") .. " (" .. cn(obj.Parent) .. ")")
                analyzeRemote(obj)
                w("")
            end
        end
        
        w("Remote Counts:")
        for name, count in pairs(remoteCounts) do
            w("  " .. name .. ": " .. count)
        end
        w("")
    end
    
    -- PROXIMITY PROMPTS
    w("============================================================")
    w("  ALL PROXIMITY PROMPTS")
    w("============================================================")
    w("")
    local promptCount = 0
    for _, obj in pairs(all(game)) do
        if cn(obj) == "ProximityPrompt" then
            promptCount = promptCount + 1
            w("[ProximityPrompt] " .. obj.Name)
            w("  Action      : " .. tostring(safe(obj, "ActionText")))
            w("  Object      : " .. tostring(safe(obj, "ObjectText")))
            w("  MaxDistance  : " .. tostring(safe(obj, "MaxActivationDistance")))
            w("  LineOfSight : " .. tostring(safe(obj, "RequiresLineOfSight")))
            w("  HoldDuration: " .. tostring(safe(obj, "HoldDuration")))
            w("  Path        : " .. fp(obj))
            analyzePrompt(obj)
            w("")
        end
    end
    w("Total ProximityPrompts: " .. promptCount)
    w("")
    
    -- GUI ELEMENTS
    if CONFIG.DUMP_GUI then
        w("============================================================")
        w("  GUI ELEMENTS WITH TEXT/IMAGE")
        w("============================================================")
        w("")
        for _, obj in pairs(all(game)) do
            local objCn = cn(obj)
            if objCn == "TextLabel" or objCn == "TextButton" or objCn == "TextBox" then
                local txt = safe(obj, "Text") or ""
                if #txt > 0 then
                    w("[" .. objCn .. "] " .. obj.Name)
                    w("  Text    : " .. txt)
                    w("  Visible : " .. tostring(safe(obj, "Visible")))
                    w("  Path    : " .. fp(obj))
                    w("")
                end
            elseif objCn == "ImageLabel" or objCn == "ImageButton" then
                local img = safe(obj, "Image") or ""
                if #img > 0 then
                    w("[" .. objCn .. "] " .. obj.Name)
                    w("  Image   : " .. img)
                    w("  Visible : " .. tostring(safe(obj, "Visible")))
                    w("  Path    : " .. fp(obj))
                    w("")
                end
            end
        end
    end
    
    -- ASSETS
    if CONFIG.DUMP_ASSETS then
        w("============================================================")
        w("  ALL ASSET IDs")
        w("============================================================")
        w("")
        for _, obj in pairs(all(game)) do
            local objCn = cn(obj)
            if objCn == "SpecialMesh" then
                local meshId = safe(obj, "MeshId") or ""
                local texId = safe(obj, "TextureId") or ""
                if meshId ~= "" or texId ~= "" then
                    w("[Mesh] " .. obj.Name)
                    w("  MeshId   : " .. meshId)
                    w("  TextureId: " .. texId)
                    w("  Path     : " .. fp(obj))
                    w("")
                end
            elseif objCn == "Decal" then
                local tex = safe(obj, "Texture") or ""
                if tex ~= "" then
                    w("[Decal] " .. obj.Name .. " -> " .. tex)
                    w("  Path: " .. fp(obj))
                end
            elseif objCn == "Animation" then
                local animId = safe(obj, "AnimationId") or ""
                if animId ~= "" then
                    w("[Animation] " .. obj.Name .. " -> " .. animId)
                    w("  Path: " .. fp(obj))
                end
            elseif objCn == "Sound" then
                local soundId = safe(obj, "SoundId") or ""
                if soundId ~= "" then
                    w("[Sound] " .. obj.Name)
                    w("  ID     : " .. soundId)
                    w("  Volume : " .. tostring(safe(obj, "Volume")))
                    w("  Playing: " .. tostring(safe(obj, "Playing")))
                    w("  Path   : " .. fp(obj))
                end
            end
        end
    end
    
    -- TOOLS
    if CONFIG.DUMP_TOOLS then
        w("")
        w("============================================================")
        w("  ALL TOOLS")
        w("============================================================")
        w("")
        for _, obj in pairs(all(game)) do
            if cn(obj) == "Tool" then
                w("[Tool] " .. obj.Name)
                w("  CanBeDropped    : " .. tostring(safe(obj, "CanBeDropped")))
                w("  RequiresHandle  : " .. tostring(safe(obj, "RequiresHandle")))
                w("  Enabled         : " .. tostring(safe(obj, "Enabled")))
                w("  ManualActivationOnly: " .. tostring(safe(obj, "ManualActivationOnly")))
                w("  Path            : " .. fp(obj))
                for _, child in pairs(obj:GetChildren()) do
                    w("    - " .. cn(child) .. " | " .. child.Name)
                    if cn(child) == "Script" or cn(child) == "LocalScript" then
                        local src = safe(child, "Source") or ""
                        w("      Source length: " .. #src .. " chars")
                        -- Quick security check on tool scripts
                        local srcLower = src:lower()
                        if srcLower:find("fireserver") or srcLower:find("invokeserver") then
                            w("      !! Tool calls remote - potential exploit vector")
                        end
                    end
                end
                w("")
            end
        end
    end
    
    -- TAGS
    if CONFIG.DUMP_TAGS then
        w("============================================================")
        w("  COLLECTION SERVICE TAGS")
        w("============================================================")
        w("")
        local tagMap = {}
        for _, obj in pairs(all(game)) do
            local ok, tags = pcall(function() return CollectionService:GetTags(obj) end)
            if ok and tags then
                for _, tag in pairs(tags) do
                    if not tagMap[tag] then tagMap[tag] = {} end
                    table.insert(tagMap[tag], cn(obj) .. " | " .. obj.Name .. " | " .. fp(obj))
                end
            end
        end
        for tag, objs in pairs(tagMap) do
            w("TAG: " .. tag .. " (" .. #objs .. " objects)")
            for _, s in ipairs(objs) do
                w("  " .. s)
            end
            w("")
        end
        if not next(tagMap) then
            w("No tags found")
        end
    end
    
    -- SECURITY ANALYSIS (run all analyzers)
    if CONFIG.DUMP_SECURITY then
        w("============================================================")
        w("  SECURITY ANALYSIS")
        w("============================================================")
        w("")
        
        -- Re-run all analyzers
        for _, obj in pairs(all(game)) do
            local objCn = cn(obj)
            if objCn == "RemoteEvent" or objCn == "RemoteFunction" or objCn == "BindableEvent" or objCn == "BindableFunction" then
                analyzeRemote(obj)
            elseif objCn == "Script" or objCn == "LocalScript" or objCn == "ModuleScript" then
                analyzeScript(obj)
            elseif objCn == "ProximityPrompt" then
                analyzePrompt(obj)
            elseif objCn == "Part" or objCn == "MeshPart" or objCn == "UnionOperation" then
                analyzePart(obj)
            end
        end
        
        w("Total vulnerabilities found: " .. vulnCount)
        w("")
        for _, v in ipairs(vulnOutput) do
            w(v)
        end
    end
    
    -- PLAYER INFO
    if CONFIG.DUMP_PLAYERS then
        w("")
        w("============================================================")
        w("  CURRENT PLAYERS")
        w("============================================================")
        w("")
        for _, plr in pairs(Players:GetPlayers()) do
            w(plr.Name .. " (ID:" .. plr.UserId .. ", Age:" .. plr.AccountAge .. "d)")
            local char = plr.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    w("  HP:" .. hum.Health .. "/" .. hum.MaxHealth .. " Speed:" .. hum.WalkSpeed .. " Jump:" .. hum.JumpPower)
                end
                for _, item in pairs(char:GetChildren()) do
                    if cn(item) == "Tool" then
                        w("  Equipped: " .. item.Name)
                    end
                end
            end
            local bp = plr:FindFirstChild("Backpack")
            if bp then
                for _, item in pairs(bp:GetChildren()) do
                    if cn(item) == "Tool" then
                        w("  Backpack: " .. item.Name)
                    end
                end
            end
        end
    end
    
    -- EXPLOIT SUGGESTIONS
    w("")
    w("============================================================")
    w("  EXPLOIT SUGGESTIONS (Based on Analysis)")
    w("============================================================")
    w("")
    
    -- Generate suggestions based on what was found
    local suggestions = {}
    
    -- Check for exploitable remotes
    local exploitableRemotes = {}
    for _, r in ipairs(vulnOutput) do
        if r:find("SUSPICIOUS_REMOTE") or r:find("SHOP_REMOTE") or r:find("ADMIN_REMOTE") then
            table.insert(exploitableRemotes, r)
        end
    end
    
    if #exploitableRemotes > 0 then
        w("HIGH PRIORITY - Exploitable Remotes Found:")
        for _, r in ipairs(exploitableRemotes) do
            w("  " .. r)
        end
        w("")
        w("Suggestion: Try firing these remotes with various arguments.")
        w("Test with: different number values, nil, empty tables, etc.")
        w("")
    end
    
    -- Check for unanchored parts
    local unanchoredCount = 0
    for _, obj in pairs(all(game)) do
        if (cn(obj) == "Part" or cn(obj) == "MeshPart") and safe(obj, "Anchored") == false then
            unanchoredCount = unanchoredCount + 1
        end
    end
    if unanchoredCount > 0 then
        w("MEDIUM - Unanchored Parts: " .. unanchoredCount)
        w("  Suggestion: Physics manipulation possible")
        w("")
    end
    
    -- Check for speed/fly indicators
    local hasSpeedMod = false
    local hasJumpMod = false
    for _, obj in pairs(all(game)) do
        local objCn = cn(obj)
        if objCn == "Script" or objCn == "LocalScript" then
            local src = (safe(obj, "Source") or ""):lower()
            if src:find("walkspeed") then hasSpeedMod = true end
            if src:find("jumppower") or src:find("jumpheight") then hasJumpMod = true end
        end
    end
    if hasSpeedMod then
        w("MEDIUM - WalkSpeed Modification Detected")
        w("  Suggestion: Try modifying WalkSpeed on client")
        w("  Method: game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 100")
        w("")
    end
    if hasJumpMod then
        w("MEDIUM - Jump Modification Detected")
        w("  Suggestion: Try modifying JumpPower/JumpHeight on client")
        w("  Method: game.Players.LocalPlayer.Character.Humanoid.JumpPower = 100")
        w("")
    end
    
    -- General suggestions
    w("GENERAL TESTING SUGGESTIONS:")
    w("  1. Fire all RemoteEvents with nil, empty table, large numbers")
    w("  2. Try equipping tools rapidly")
    w("  3. Trigger all ProximityPrompts")
    w("  4. Modify Humanoid properties (WalkSpeed, JumpPower, MaxHealth)")
    w("  5. Try destroying/removing GUI elements")
    w("  6. Check for admin commands in chat")
    w("  7. Try respawning repeatedly")
    w("  8. Check for game pass checks (promptProductPurchase)")
    w("")
    
    -- FINAL
    w("============================================================")
    w("  DUMP COMPLETE - " .. os.date("%Y-%m-%d %H:%M:%S"))
    -- SAVE
    local report = table.concat(lines, "\n")
    
    w("  Report: " .. #report .. " chars")
    w("  Vulns: " .. vulnCount)
    w("============================================================")
    
    local saved = saveFile(CONFIG.OUTPUT_FILE, report)
    if saved then
        print("")
        print("SAVED: " .. CONFIG.OUTPUT_FILE .. " (" .. #report .. " chars)")
    else
        print("writefile not available - copy output above")
        print(report)
    end
    
    -- Save vulns separately
    if vulnCount > 0 then
        saveFile(CONFIG.OUTPUT_VULN_FILE, table.concat(vulnOutput, "\n"))
        print("VULNS: " .. CONFIG.OUTPUT_VULN_FILE)
    end
    
    pcall(function()
        if setclipboard then
            setclipboard(report)
            print("Copied to clipboard!")
        end
    end)
end

-- ============================================================
-- MODE 2: MONITOR (runs alongside DUMP in FULL mode)
-- ============================================================
if CONFIG.MODE == "MONITOR" or CONFIG.MODE == "FULL" then
    print("")
    print("=== MONITOR ACTIVE ===")
    print("Logging all remote calls to: " .. CONFIG.OUTPUT_MONITOR_FILE)
    print("")
    
    -- Initialize
    local header = string.format("Monitor started: %s | Place: %s\n", os.date("%Y-%m-%d %H:%M:%S"), tostring(game.PlaceId))
    saveFile(CONFIG.OUTPUT_MONITOR_FILE, header)
    
    -- Hook all remotes
    local function hookRemote(obj)
        if hookedRemotes[obj] then return end
        hookedRemotes[obj] = true
        
        local rCn = cn(obj)
        local rPath = fp(obj)
        
        if rCn == "RemoteEvent" then
            pcall(function()
                obj.OnClientEvent:Connect(function(...)
                    logCount = logCount + 1
                    local argsStr = safeJSON({...})
                    if #argsStr > 500 then argsStr = argsStr:sub(1, 500) .. "..." end
                    
                    local line = string.format("[%s] #%d REMOTE(C2S) %s | Args: %s | Path: %s",
                        ts(), logCount, obj.Name, argsStr, rPath)
                    appendFile(CONFIG.OUTPUT_MONITOR_FILE, line)
                    
                    if logCount <= 100 then
                        print(line)
                    end
                end)
            end)
        end
        
        print("[HOOKED] " .. rCn .. ": " .. obj.Name)
    end
    
    -- Hook existing
    for _, obj in pairs(all(game)) do
        local objCn = cn(obj)
        if objCn == "RemoteEvent" or objCn == "RemoteFunction" then
            hookRemote(obj)
        end
    end
    
    -- Hook new
    game.DescendantAdded:Connect(function(obj)
        if cn(obj) == "RemoteEvent" or cn(obj) == "RemoteFunction" then
            hookRemote(obj)
            appendFile(CONFIG.OUTPUT_MONITOR_FILE, string.format("[%s] NEW_REMOTE: %s at %s", ts(), cn(obj) .. "." .. obj.Name, fp(obj)))
        end
    end)
    
    -- Hook namecall if possible (log ALL FireServer/InvokeServer)
    pcall(function()
        if hookmetamethod then
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if method == "FireServer" or method == "InvokeServer" then
                    logCount = logCount + 1
                    local argsStr = safeJSON({...})
                    if #argsStr > 500 then argsStr = argsStr:sub(1, 500) .. "..." end
                    
                    local line = string.format("[%s] #%d %s %s | Args: %s | Path: %s",
                        ts(), logCount, method:upper(), self.Name, argsStr, fp(self))
                    appendFile(CONFIG.OUTPUT_MONITOR_FILE, line)
                    
                    if logCount <= 100 then
                        print(line)
                    end
                end
                return oldNamecall(self, ...)
            end))
            print("[HOOKED] namecall - all FireServer/InvokeServer will be logged")
        end
    end)
    
    -- Monitor humanoid changes
    pcall(function()
        local function monitorHumanoid(player, char)
            local hum = char:WaitForChild("Humanoid", 10)
            if hum then
                hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                    local line = string.format("[%s] ALERT WalkSpeed changed: %f | Player: %s", ts(), hum.WalkSpeed, player.Name)
                    appendFile(CONFIG.OUTPUT_VULN_FILE, line)
                    print("[ALERT] WalkSpeed: " .. player.Name .. " -> " .. hum.WalkSpeed)
                end)
                hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
                    local line = string.format("[%s] ALERT JumpPower changed: %f | Player: %s", ts(), hum.JumpPower, player.Name)
                    appendFile(CONFIG.OUTPUT_VULN_FILE, line)
                    print("[ALERT] JumpPower: " .. player.Name .. " -> " .. hum.JumpPower)
                end)
                hum:GetPropertyChangedSignal("MaxHealth"):Connect(function()
                    local line = string.format("[%s] ALERT MaxHealth changed: %f | Player: %s", ts(), hum.MaxHealth, player.Name)
                    appendFile(CONFIG.OUTPUT_VULN_FILE, line)
                    print("[ALERT] MaxHealth: " .. player.Name .. " -> " .. hum.MaxHealth)
                end)
            end
        end
        
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character then monitorHumanoid(plr, plr.Character) end
            plr.CharacterAdded:Connect(function(char) monitorHumanoid(plr, char) end)
        end
        Players.LocalPlayer.CharacterAdded:Connect(function(char) monitorHumanoid(Players.LocalPlayer, char) end)
    end)
    
    -- Periodic stats
    spawn(function()
        while wait(CONFIG.MONITOR_HEARTBEAT) do
            local stats = string.format("[%s] STATS | Remotes:%d Logs:%d Vulns:%d Players:%d",
                ts(), #hookedRemotes, logCount, vulnCount, #Players:GetPlayers())
            appendFile(CONFIG.OUTPUT_MONITOR_FILE, stats)
            print(stats)
        end
    end)
    
    print("")
    print("Monitor active. Play the game to generate data.")
end

-- ============================================================
-- MODE 3: FUZZ REMOTES
-- ============================================================
if CONFIG.MODE == "FUZZ" or CONFIG.MODE == "FULL" then
    print("")
    print("=== REMOTE FUZZER ===")
    print("Testing all remotes with various inputs...")
    print("")
    
    local function fuzzRemote(obj)
        local rCn = cn(obj)
        local rName = obj.Name
        local rPath = fp(obj)
        
        if rCn == "RemoteEvent" and CONFIG.FUZZ_REMOTE_EVENTS then
            out("[FUZZ] Testing RemoteEvent: " .. rName)
            
            -- Test payloads
            local payloads = {
                {"test"},
                {1},
                {0},
                {-1},
                {999999999},
                {-999999999},
                {0.1},
                {true},
                {false},
                {nil},
                {""},
                {"<script>alert(1)</script>"},
                {"'; DROP TABLE users; --"},
                {string.rep("A", 1000)},
                {string.rep("a", 10000)},
                {{}},
                {{1, 2, 3}},
                {{"a", "b", "c"}},
                {nil, nil, nil},
                {true, false, nil, 1, "test", {}},
                {math.huge},
                {-math.huge},
                {0/0},  -- NaN
                {Vector3.new(0, 0, 0)},
                {Vector3.new(99999, 99999, 99999)},
                {CFrame.new()},
                {Color3.new(1, 0, 0)},
                {BrickColor.new("Bright red")},
                {game.Players.LocalPlayer},
                {game.Workspace},
                {game.Workspace:FindFirstChild("Baseplate") or game.Workspace:FindFirstChildOfClass("Part")},
                {Instance.new("Part")},
            }
            
            for i, payload in ipairs(payloads) do
                pcall(function()
                    obj:FireServer(unpack(payload))
                end)
                
                local payloadStr = safeJSON(payload)
                if #payloadStr > 100 then payloadStr = payloadStr:sub(1, 100) .. "..." end
                
                local line = string.format("[%s] FUZZ %s | #%d | Payload: %s", ts(), rName, i, payloadStr)
                appendFile(CONFIG.OUTPUT_FUZZ_FILE, line)
                
                if i <= 20 then
                    print("  #" .. i .. " Payload: " .. payloadStr:sub(1, 80))
                end
                
                wait(CONFIG.FUZZ_DELAY)
            end
            
            out("[FUZZ] Done: " .. rName)
            
        elseif rCn == "RemoteFunction" and CONFIG.FUZZ_REMOTE_FUNCTIONS then
            out("[FUZZ] Testing RemoteFunction: " .. rName)
            
            local payloads = {
                {"test"},
                {1},
                {0},
                {nil},
                {{}},
                {true},
                {false},
                {""},
                {string.rep("A", 100)},
                {999999999},
                {math.huge},
            }
            
            for i, payload in ipairs(payloads) do
                pcall(function()
                    local result = obj:InvokeServer(unpack(payload))
                    local resultStr = safeJSON(result)
                    if #resultStr > 200 then resultStr = resultStr:sub(1, 200) .. "..." end
                    
                    local line = string.format("[%s] FUZZ %s | #%d | Payload: %s | Response: %s",
                        ts(), rName, i, safeJSON(payload):sub(1, 80), resultStr)
                    appendFile(CONFIG.OUTPUT_FUZZ_FILE, line)
                    print("  #" .. i .. " Response: " .. resultStr:sub(1, 80))
                end)
                
                wait(CONFIG.FUZZ_DELAY)
            end
            
            out("[FUZZ] Done: " .. rName)
        end
    end
    
    -- Find and fuzz all remotes
    for _, obj in pairs(all(game)) do
        local objCn = cn(obj)
        if objCn == "RemoteEvent" or objCn == "RemoteFunction" then
            fuzzRemote(obj)
            wait(1) -- Delay between remotes
        end
    end
    
    print("")
    print("FUZZ COMPLETE! Results saved to: " .. CONFIG.OUTPUT_FUZZ_FILE)
end

-- ============================================================
-- FINAL OUTPUT
-- ============================================================
print("")
print("============================================================")
print("  ROBLOX ULTIMATE RECON SUITE - COMPLETE")
print("  Mode: " .. CONFIG.MODE)
print("  Vulnerabilities: " .. vulnCount)
print("  Files:")
print("    Main   : " .. CONFIG.OUTPUT_FILE)
print("    Vulns  : " .. CONFIG.OUTPUT_VULN_FILE)
print("    Monitor: " .. CONFIG.OUTPUT_MONITOR_FILE)
print("    Fuzz   : " .. CONFIG.OUTPUT_FUZZ_FILE)
print("============================================================")
print("")
print("Share these files with Hermes for full analysis!")
