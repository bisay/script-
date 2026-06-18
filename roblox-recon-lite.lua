--[[
    ROBLOX RECON SUITE v3 - LIGHTWEIGHT
    Fast, single-pass scan. No crash.
    
    MODE: "DUMP" | "MONITOR" | "FUZZ"
]]
local MODE = "DUMP"

-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

-- UTILS
local function safe(obj, prop)
    local ok, val = pcall(function() return obj[prop] end)
    return ok and val or nil
end

local function cn(obj)
    local ok, c = pcall(function() return obj.ClassName end)
    return ok and c or "?"
end

local function fp(obj)
    local parts = {}
    local cur = obj
    while cur and cur ~= game do
        table.insert(parts, 1, cur.Name)
        cur = cur.Parent
    end
    return "game." .. table.concat(parts, ".")
end

local function saveFile(name, content)
    pcall(function()
        if writefile then writefile(name, content) end
    end)
end

local function appendFile(name, line)
    pcall(function()
        if appendfile then appendfile(name, line .. "\n") end
    end)
end

local out = {}
local vulns = {}
local vulnCount = 0

local function w(line)
    table.insert(out, line)
end

local function addVuln(sev, cat, desc, path)
    vulnCount = vulnCount + 1
    local e = string.format("[%s] #%d %s: %s -> %s", sev, vulnCount, cat, desc, path or "?")
    table.insert(vulns, e)
    print("[VULN-" .. sev .. "] " .. cat .. ": " .. desc)
end

local placeId = tostring(game.PlaceId)
local fileName = "recon_" .. placeId .. ".txt"

-- ============================================================
-- SINGLE PASS SCAN
-- ============================================================
print("=== ROBLOX RECON v3 ===")
print("Scanning " .. placeId .. "...")
print("")

w("============================================================")
w("ROBLOX RECON v3 - " .. os.date("%Y-%m-%d %H:%M:%S"))
w("Place: " .. placeId)
w("============================================================")
w("")

-- Game info
pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    w("Game: " .. (info.Name or "?"))
    w("Creator: " .. (info.Creator and info.Creator.Name or "?"))
end)
w("Players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
w("")

-- Counters
local count = 0
local scripts = {}
local remotes = {}
local prompts = {}
local tools = {}
local guis = {}
local assets = {}
local tags = {}

-- SINGLE PASS through all descendants
for _, obj in pairs(game:GetDescendants()) do
    count = count + 1
    local c = cn(obj)
    local p = fp(obj)
    
    if c == "Script" or c == "LocalScript" or c == "ModuleScript" then
        local src = safe(obj, "Source") or ""
        table.insert(scripts, {name=obj.Name, type=c, path=p, src=src, disabled=safe(obj, "Disabled")})
        
        -- Quick vuln scan on source
        local sl = src:lower()
        if sl:find("httpservice") then addVuln("HIGH", "HTTP", "HttpService usage", p) end
        if sl:find("loadstring") then addVuln("CRIT", "LOADSTRING", "loadstring()", p) end
        if sl:find("datastore") then addVuln("HIGH", "DATASTORE", "DataStore access", p) end
        if sl:find("walkspeed") then addVuln("MED", "SPEED", "WalkSpeed mod", p) end
        if sl:find("jumppower") or sl:find("jumpheight") then addVuln("MED", "JUMP", "Jump mod", p) end
        if sl:find("filteringenabled") then addVuln("CRIT", "FILTER", "FilteringEnabled", p) end
        if sl:find("hookfunction") or sl:find("hookmetamethod") then addVuln("CRIT", "HOOK", "Function hooking", p) end
        if sl:find("getrawmetatable") then addVuln("CRIT", "RAW_META", "Raw metatable", p) end
        if sl:find("checkcaller") then addVuln("HIGH", "ANTICHEAT", "checkcaller (anti-exploit)", p) end
        if sl:find("identifyexecutor") then addVuln("HIGH", "ANTICHEAT", "Executor detection", p) end
        if sl:find("leaderstats") then addVuln("MED", "LEADERSTATS", "Leaderstats", p) end
        if sl:find("teleport") then addVuln("MED", "TELEPORT", "TeleportService", p) end
        if sl:find("marketplaceservice") then addVuln("MED", "MARKETPLACE", "MarketplaceService", p) end
        
    elseif c == "RemoteEvent" or c == "RemoteFunction" or c == "BindableEvent" or c == "BindableFunction" then
        table.insert(remotes, {name=obj.Name, type=c, path=p, parent=safe(obj.Parent, "Name")})
        
        -- Vuln scan on remote name
        local nl = obj.Name:lower()
        local sus = {"buy","purchase","shop","give","grant","admin","ban","kick","teleport","tp","fly","speed","god","kill","money","cash","coins","gems","reward","claim","daily","spin","add","remove","delete","set","item","weapon","equip","spawn","health","damage","heal","level","exp","unlock","save","load","trade","drop","open","chest","box"}
        for _, kw in ipairs(sus) do
            if nl:find(kw) then
                addVuln("HIGH", "SUS_REMOTE", "Remote '" .. obj.Name .. "' keyword: " .. kw, p)
                break
            end
        end
        
        local par = safe(obj.Parent, "Name")
        if par then
            local pl = par:lower()
            if pl:find("admin") or pl:find("mod") or pl:find("debug") or pl:find("cheat") then
                addVuln("CRIT", "ADMIN_REMOTE", "In admin container: " .. par, p)
            end
            if pl:find("shop") or pl:find("store") then
                addVuln("MED", "SHOP_REMOTE", "In shop container: " .. par, p)
            end
        end
        
        if c == "RemoteFunction" then
            addVuln("MED", "REMOTEFUNCTION", "Client can invoke: " .. obj.Name, p)
        end
        
    elseif c == "ProximityPrompt" then
        table.insert(prompts, {name=obj.Name, path=p, action=safe(obj, "ActionText"), objText=safe(obj, "ObjectText"), dist=safe(obj, "MaxActivationDistance"), los=safe(obj, "RequiresLineOfSight")})
        
    elseif c == "Tool" then
        table.insert(tools, {name=obj.Name, path=p})
        
    elseif c == "ScreenGui" or c == "Frame" or c == "TextButton" or c == "TextLabel" then
        local txt = safe(obj, "Text") or ""
        table.insert(guis, {name=obj.Name, type=c, path=p, text=txt, visible=safe(obj, "Visible")})
        
    elseif c == "SpecialMesh" then
        local mid = safe(obj, "MeshId")
        if mid and mid ~= "" then table.insert(assets, {name=obj.Name, type="Mesh", id=mid, path=p}) end
    elseif c == "Decal" or c == "Texture" then
        local tex = safe(obj, "Texture")
        if tex and tex ~= "" then table.insert(assets, {name=obj.Name, type="Decal", id=tex, path=p}) end
    elseif c == "Animation" then
        local aid = safe(obj, "AnimationId")
        if aid and aid ~= "" then table.insert(assets, {name=obj.Name, type="Animation", id=aid, path=p}) end
    elseif c == "Sound" then
        local sid = safe(obj, "SoundId")
        if sid and sid ~= "" then table.insert(assets, {name=obj.Name, type="Sound", id=sid, path=p}) end
    end
end

-- CollectionService tags (separate pass, lightweight)
pcall(function()
    for _, obj in pairs(game:GetDescendants()) do
        local ok, t = pcall(function() return CollectionService:GetTags(obj) end)
        if ok and t then
            for _, tag in ipairs(t) do
                if not tags[tag] then tags[tag] = 0 end
                tags[tag] = tags[tag] + 1
            end
        end
    end
end)

print("Scanned " .. count .. " instances")
w("Total instances: " .. count)
w("")

-- ============================================================
-- OUTPUT: SCRIPTS
-- ============================================================
w("============================================================")
w("SCRIPTS (" .. #scripts .. ")")
w("============================================================")
w("")
for _, s in ipairs(scripts) do
    local lc = select(2, s.src:gsub("\n", "\n"))
    w(s.type .. " | " .. s.name)
    w("  Path: " .. s.path)
    w("  Lines: ~" .. lc .. "  Chars: " .. #s.src)
    if s.disabled then w("  DISABLED") end
    
    -- Dump source if not too long
    if #s.src > 0 and #s.src < 5000 then
        w("  --- SOURCE ---")
        local ln = 1
        for line in s.src:gmatch("([^\n]*)\n?") do
            w(string.format("  %3d| %s", ln, line))
            ln = ln + 1
        end
        w("  --- END ---")
    elseif #s.src >= 5000 then
        w("  [Source too long: " .. #s.src .. " chars - truncated]")
        w("  First 500 chars:")
        w("  " .. s.src:sub(1, 500))
    end
    w("")
end

-- ============================================================
-- OUTPUT: REMOTES
-- ============================================================
w("============================================================")
w("REMOTES (" .. #remotes .. ")")
w("============================================================")
w("")
for _, r in ipairs(remotes) do
    w(r.type .. " | " .. r.name)
    w("  Path: " .. r.path)
    w("  Parent: " .. tostring(r.parent))
    w("")
end

-- ============================================================
-- OUTPUT: PROXIMITY PROMPTS
-- ============================================================
w("============================================================")
w("PROXIMITY PROMPTS (" .. #prompts .. ")")
w("============================================================")
w("")
for _, pr in ipairs(prompts) do
    w(pr.name)
    w("  Action: " .. tostring(pr.action))
    w("  Object: " .. tostring(pr.objText))
    w("  Dist: " .. tostring(pr.dist) .. "  LOS: " .. tostring(pr.los))
    w("  Path: " .. pr.path)
    w("")
end

-- ============================================================
-- OUTPUT: TOOLS
-- ============================================================
w("============================================================")
w("TOOLS (" .. #tools .. ")")
w("============================================================")
w("")
for _, t in ipairs(tools) do
    w(t.name .. " -> " .. t.path)
end
w("")

-- ============================================================
-- OUTPUT: GUI WITH TEXT
-- ============================================================
w("============================================================")
w("GUI ELEMENTS (" .. #guis .. ")")
w("============================================================")
w("")
for _, g in ipairs(guis) do
    if g.text ~= "" or g.type == "ScreenGui" then
        w(g.type .. " | " .. g.name)
        if g.text ~= "" then w("  Text: " .. g.text:sub(1, 100)) end
        w("  Visible: " .. tostring(g.visible))
        w("  Path: " .. g.path)
        w("")
    end
end

-- ============================================================
-- OUTPUT: ASSETS
-- ============================================================
w("============================================================")
w("ASSETS (" .. #assets .. ")")
w("============================================================")
w("")
for _, a in ipairs(assets) do
    w(a.type .. " | " .. a.name .. " -> " .. a.id)
    w("  Path: " .. a.path)
    w("")
end

-- ============================================================
-- OUTPUT: TAGS
-- ============================================================
w("============================================================")
w("COLLECTION SERVICE TAGS")
w("============================================================")
w("")
for tag, cnt in pairs(tags) do
    w(tag .. ": " .. cnt .. " objects")
end
w("")

-- ============================================================
-- OUTPUT: PLAYERS
-- ============================================================
w("============================================================")
w("PLAYERS")
w("============================================================")
w("")
for _, plr in ipairs(Players:GetPlayers()) do
    w(plr.Name .. " (ID:" .. plr.UserId .. " Age:" .. plr.AccountAge .. "d)")
    local char = plr.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            w("  HP:" .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. " Speed:" .. hum.WalkSpeed .. " Jump:" .. hum.JumpPower)
        end
    end
    w("")
end

-- ============================================================
-- OUTPUT: VULNERABILITIES
-- ============================================================
w("============================================================")
w("VULNERABILITIES (" .. vulnCount .. ")")
w("============================================================")
w("")
for _, v in ipairs(vulns) do
    w(v)
    w("")
end

-- ============================================================
-- EXPLOIT SUGGESTIONS
-- ============================================================
w("============================================================")
w("EXPLOIT SUGGESTIONS")
w("============================================================")
w("")

-- Speed
local hasSpeed = false
local hasJump = false
for _, v in ipairs(vulns) do
    if v:find("SPEED") then hasSpeed = true end
    if v:find("JUMP") then hasJump = true end
end
if hasSpeed then
    w("[SPEED] Try: game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 100")
end
if hasJump then
    w("[JUMP] Try: game.Players.LocalPlayer.Character.Humanoid.JumpPower = 100")
end

-- Remotes
if #remotes > 0 then
    w("[REMOTES] Test firing these remotes with various args:")
    for _, r in ipairs(remotes) do
        w("  " .. r.path)
    end
    w("  Test payloads: nil, 0, -1, 999999999, true, false, {}, '', math.huge")
end

-- Prompts
if #prompts > 0 then
    w("[PROMPTS] Try triggering all prompts from distance:")
    for _, pr in ipairs(prompts) do
        w("  " .. pr.name .. " (" .. tostring(pr.action) .. ")")
    end
end

w("")
w("============================================================")
w("SCAN COMPLETE - " .. os.date("%Y-%m-%d %H:%M:%S"))
w("============================================================")

-- SAVE
local report = table.concat(out, "\n")
saveFile(fileName, report)
print("")
print("SAVED: " .. fileName .. " (" .. #report .. " chars)")
print("Vulns found: " .. vulnCount)

pcall(function()
    if setclipboard then
        setclipboard(report)
        print("Copied to clipboard!")
    end
end)

-- ============================================================
-- MONITOR MODE (optional, lightweight)
-- ============================================================
if MODE == "MONITOR" then
    print("")
    print("=== MONITOR MODE ===")
    print("Watching for remote calls...")
    
    local hooked = {}
    local logFile = "monitor_" .. placeId .. ".txt"
    saveFile(logFile, "Monitor started " .. os.date() .. "\n\n")
    
    local function hook(r)
        if hooked[r] then return end
        hooked[r] = true
        if cn(r) == "RemoteEvent" then
            pcall(function()
                r.OnClientEvent:Connect(function(...)
                    local args = {...}
                    local s = "[" .. os.date("%H:%M:%S") .. "] " .. r.Name .. " | "
                    pcall(function() s = s .. HttpService:JSONEncode(args) end)
                    appendFile(logFile, s)
                    print(s:sub(1, 120))
                end)
            end)
        end
        print("[HOOKED] " .. r.Name)
    end
    
    for _, obj in pairs(game:GetDescendants()) do
        if cn(obj) == "RemoteEvent" or cn(obj) == "RemoteFunction" then
            hook(obj)
        end
    end
    
    game.DescendantAdded:Connect(function(obj)
        if cn(obj) == "RemoteEvent" or cn(obj) == "RemoteFunction" then
            hook(obj)
        end
    end)
    
    -- Hook FireServer via namecall
    pcall(function()
        if hookmetamethod then
            local old
            old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local m = getnamecallmethod()
                if m == "FireServer" or m == "InvokeServer" then
                    local s = "[" .. os.date("%H:%M:%S") .. "] " .. m .. " " .. self.Name .. " | "
                    pcall(function() s = s .. HttpService:JSONEncode({...}) end)
                    appendFile(logFile, s)
                    print(s:sub(1, 120))
                end
                return old(self, ...)
            end))
            print("[HOOKED] namecall - all FireServer/InvokeServer logged")
        end
    end)
    
    print("Monitor active. Play the game to capture traffic.")
end

-- ============================================================
-- FUZZ MODE (optional)
-- ============================================================
if MODE == "FUZZ" then
    print("")
    print("=== FUZZ MODE ===")
    print("Testing remotes...")
    
    local fuzzFile = "fuzz_" .. placeId .. ".txt"
    saveFile(fuzzFile, "Fuzz started " .. os.date() .. "\n\n")
    
    local payloads = {
        {"test"}, {1}, {0}, {-1}, {999999999}, {-999999999},
        {true}, {false}, {nil}, {""}, {{}},
        {math.huge}, {-math.huge},
        {string.rep("A", 1000)},
        {Vector3.new(0,0,0)}, {CFrame.new()}, {Color3.new(1,0,0)},
    }
    
    for _, obj in pairs(game:GetDescendants()) do
        local c = cn(obj)
        if c == "RemoteEvent" then
            print("[FUZZ] " .. obj.Name)
            for i, payload in ipairs(payloads) do
                pcall(function()
                    obj:FireServer(unpack(payload))
                end)
                local s = string.format("#%d %s | %s", i, obj.Name, tostring(payload[1]):sub(1, 50))
                appendFile(fuzzFile, s)
                wait(0.3)
            end
        elseif c == "RemoteFunction" then
            print("[FUZZ] " .. obj.Name)
            for i, payload in ipairs(payloads) do
                pcall(function()
                    local r = obj:InvokeServer(unpack(payload))
                    local s = string.format("#%d %s | %s | Response: %s", i, obj.Name, tostring(payload[1]):sub(1, 50), tostring(r):sub(1, 50))
                    appendFile(fuzzFile, s)
                end)
                wait(0.3)
            end
        end
    end
    
    print("Fuzz complete! Results: " .. fuzzFile)
end

print("")
print("=== DONE ===")
print("File: " .. fileName)
print("Vulns: " .. vulnCount)
