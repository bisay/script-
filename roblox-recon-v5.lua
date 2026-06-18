--[[
    ROBLOX RECON SUITE v5 - WITH GUI
    Tap START to begin. Configure before running.
    Compatible with most executors (Synapse, Fluxus, etc)
]]

-- GUI Library (built-in, no external deps)
local player = game:GetService("Players").LocalPlayer
local gui

-- Create main screen
pcall(function()
    if syn and syn.protect_gui then
        gui = Instance.new("ScreenGui")
        gui.Name = "RobloxRecon"
        syn.protect_gui(gui)
        gui.Parent = game:GetService("CoreGui")
    else
        gui = Instance.new("ScreenGui")
        gui.Name = "RobloxRecon"
        gui.Parent = player:WaitForChild("PlayerGui")
    end
end)

-- ============================================================
-- GUI BUILDER HELPERS
-- ============================================================
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 420, 0, 520)
frame.Position = UDim2.new(0.5, -210, 0.5, -260)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 80, 120)
stroke.Thickness = 1
stroke.Parent = frame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
title.BorderSizePixel = 0
title.Text = "ROBLOX RECON v5"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = title

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = frame

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- ============================================================
-- SETTINGS STATE
-- ============================================================
local settings = {
    MODE = "DUMP",
    OUTPUT = "workspace",
    CUSTOM_PATH = "",
    HIERARCHY_DEPTH = 10,
    MAX_SOURCE_CHARS = 5000,
    SCAN_SCRIPTS = true,
    SCAN_REMOTES = true,
    SCAN_PROMPTS = true,
    SCAN_TOOLS = true,
    SCAN_GUI = true,
    SCAN_ASSETS = true,
    SCAN_PARTS = true,
    SCAN_TAGS = true,
    SCAN_PLAYERS = true,
    SCAN_HIERARCHY = true,
}

-- Helper: Create section label
local function createSectionLabel(text, y)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 22)
    label.Position = UDim2.new(0, 10, 0, y)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(180, 180, 220)
    label.TextSize = 13
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    return label
end

-- Helper: Create toggle button
local function createToggle(text, y, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 380, 0, 26)
    btn.Position = UDim2.new(0, 20, 0, y)
    btn.BackgroundColor3 = default and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(180, 60, 60)
    btn.Text = (default and "[ON] " or "[OFF] ") .. text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.Gotham
    btn.Parent = frame

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 6)
    toggleCorner.Parent = btn

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(180, 60, 60)
        btn.Text = (state and "[ON] " or "[OFF] ") .. text
        if callback then callback(state) end
    end)

    return btn
end

-- Helper: create dropdown (cycle button)
local function createDropdown(text, y, options, defaultIdx, callback)
    local idx = defaultIdx or 1
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 380, 0, 28)
    container.Position = UDim2.new(0, 20, 0, y)
    container.BackgroundTransparency = 1
    container.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 140, 0, 28)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 160, 0, 26)
    btn.Position = UDim2.new(0, 150, 0, 1)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    btn.Text = options[idx]
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.Gotham
    btn.Parent = container

    local dropCorner = Instance.new("UICorner")
    dropCorner.CornerRadius = UDim.new(0, 6)
    dropCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        idx = idx + 1
        if idx > #options then idx = 1 end
        btn.Text = options[idx]
        if callback then callback(options[idx], idx) end
    end)

    return btn
end

-- Helper: create text input
local function createTextInput(text, y, placeholder, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 380, 0, 28)
    container.Position = UDim2.new(0, 20, 0, y)
    container.BackgroundTransparency = 1
    container.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 140, 0, 28)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0, 160, 0, 26)
    input.Position = UDim2.new(0, 150, 0, 1)
    input.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    input.Text = ""
    input.PlaceholderText = placeholder
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    input.TextSize = 11
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.Parent = container

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = input

    input.FocusLost:Connect(function()
        if callback then callback(input.Text) end
    end)

    return input
end

-- ============================================================
-- BUILD GUI
-- ============================================================
local y = 50

createSectionLabel("MODE", y) y = y + 24
createDropdown("Select:", y, {"DUMP", "MONITOR", "FUZZ"}, 1, function(val)
    settings.MODE = val
end)
y = y = y + 34

createSectionLabel("OUTPUT FOLDER", y) y = y + 24
createDropdown("Location:", y, {"Desktop", "Workspace", "Custom"}, 2, function(val)
    settings.OUTPUT = val:lower()
end)
y = y + 34

createTextInput("Custom:", y, "C:\\MyFolder", function(val)
    settings.CUSTOM_PATH = val
end)
y = y + 34

createSectionLabel("SCAN OPTIONS", y) y = y + 24

createToggle("Scripts + Source", y, true, function(s) settings.SCAN_SCRIPTS = s end)
y = y + 30
createToggle("Remotes", y, true, function(s) settings.SCAN_REMOTES = s end)
y = y + 30
createToggle("Proximity Prompts", y, true, function(s) settings.SCAN_PROMPTS = s end)
y = y + 30
createToggle("Tools", y, true, function(s) settings.SCAN_TOOLS = s end)
y = y + 30
createToggle("GUI Elements", y, true, function(s) settings.SCAN_GUI = s end)
y = y + 30
createToggle("Assets (Mesh/Sound)", y, true, function(s) settings.SCAN_ASSETS = s end)
y = y + 30
createToggle("Security (Parts)", y, true, function(s) settings.SCAN_PARTS = s end)
y = y + 30
createToggle("Collection Tags", y, true, function(s) settings.SCAN_TAGS = s end)
y = y + 30
createToggle("Players", y, true, function(s) settings.SCAN_PLAYERS = s end)
y = y + 30
createToggle("Hierarchy", y, true, function(s) settings.SCAN_HIERARCHY = s end)
y = y + 34

createSectionLabel("ADVANCED", y) y = y + 24

createDropdown("Max Source:", y, {"0", "1000", "5000", "10000"}, 3, function(val)
    settings.MAX_SOURCE_CHARS = tonumber(val) or 5000
end)
y = y + 34

createDropdown("Depth:", y, {"5", "10", "15", "20"}, 2, function(val)
    settings.HIERARCHY_DEPTH = tonumber(val) or 10
end)
y = y + 40

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, y)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready. Press START."
statusLabel.TextColor3 = Color3.fromRGB(150, 200, 150)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.Parent = frame
y = y + 24

-- START button
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0, 200, 0, 40)
startBtn.Position = UDim2.new(0.5, -100, 0, y)
startBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
startBtn.Text = "START SCAN"
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.TextSize = 16
startBtn.Font = Enum.Font.GothamBold
startBtn.Parent = frame

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 8)
startCorner.Parent = startBtn

-- ============================================================
-- SCAN ENGINE (runs after START is pressed)
-- ============================================================
startBtn.MouseButton1Click:Connect(function()
    startBtn.Text = "SCANNING..."
    startBtn.BackgroundColor3 = Color3.fromRGB(180, 140, 40)
    statusLabel.Text = "Scanning game..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)

    -- Resolve output path
    local function getOutPath(filename)
        if settings.OUTPUT == "desktop" then
            return "C:\\Users\\Administrator\\Desktop\\" .. filename
        elseif settings.OUTPUT == "custom" and settings.CUSTOM_PATH ~= "" then
            return settings.CUSTOM_PATH .. "\\" .. filename
        else
            return filename
        end
    end

    local placeId = tostring(game.PlaceId)
    local fileName = getOutPath("recon_v5_" .. placeId .. ".txt")

    -- Services
    local Players = game:GetService("Players")
    local MarketplaceService = game:GetService("MarketplaceService")
    local CollectionService = game:GetService("CollectionService")
    local HttpService = game:GetService("HttpService")

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
        pcall(function() if writefile then writefile(name, content) end end)
    end
    local function appendFile(name, line)
        pcall(function() if appendfile then appendfile(name, line .. "\n") end end)
    end

    local out = {}
    local vulns = {}
    local vulnCount = 0
    local function w(line) table.insert(out, line) end
    local function addVuln(sev, cat, desc, path)
        vulnCount = vulnCount + 1
        local e = string.format("[%s] #%d %s: %s", sev, vulnCount, cat, desc)
        table.insert(vulns, e)
        print("[VULN-" .. sev .. "] " .. cat .. ": " .. desc)
    end

    -- Collectors
    local scripts, remotes, prompts, tools, guis, assets, parts = {}, {}, {}, {}, {}, {}, {}
    local tagMap = {}
    local totalCount = 0

    statusLabel.Text = "Pass 1: Collecting instances..."
    for _, obj in pairs(game:GetDescendants()) do
        totalCount = totalCount + 1
        local c = cn(obj)
        local p = fp(obj)

        if c == "Script" or c == "LocalScript" or c == "ModuleScript" then
            local src = safe(obj, "Source") or ""
            table.insert(scripts, {name=obj.Name, type=c, path=p, src=src})
            -- Vuln scan
            local sl = src:lower()
            if sl:find("httpservice") then addVuln("HIGH", "HTTP", "HttpService", p) end
            if sl:find("loadstring") then addVuln("CRIT", "LOADSTRING", "loadstring()", p) end
            if sl:find("datastore") then addVuln("HIGH", "DATASTORE", "DataStore", p) end
            if sl:find("walkspeed") then addVuln("MED", "SPEED", "WalkSpeed", p) end
            if sl:find("jumppower") then addVuln("MED", "JUMP", "JumpPower", p) end
            if sl:find("hookfunction") or sl:find("hookmetamethod") then addVuln("CRIT", "HOOK", "Function hook", p) end
            if sl:find("checkcaller") then addVuln("HIGH", "ANTICHEAT", "checkcaller", p) end
            if sl:find("identifyexecutor") then addVuln("HIGH", "ANTICHEAT", "Executor detect", p) end
        elseif c == "RemoteEvent" or c == "RemoteFunction" or c == "BindableEvent" or c == "BindableFunction" then
            table.insert(remotes, {name=obj.Name, type=c, path=p, parent=safe(obj.Parent, "Name")})
            local nl = obj.Name:lower()
            for _, kw in ipairs({"buy","purchase","shop","give","grant","admin","ban","teleport","fly","speed","god","kill","money","cash","coins","reward","claim","add","remove","item","weapon","equip","spawn","health","damage","level","unlock","save","trade","drop","chest"}) do
                if nl:find(kw) then addVuln("HIGH", "SUS_REMOTE", "'" .. obj.Name .. "' keyword: " .. kw, p) break end
            end
            local par = safe(obj.Parent, "Name")
            if par and (par:lower():find("admin") or par:lower():find("mod")) then
                addVuln("CRIT", "ADMIN_REMOTE", "In: " .. par, p)
            end
        elseif c == "ProximityPrompt" then
            table.insert(prompts, {name=obj.Name, path=p, action=safe(obj, "ActionText"), dist=safe(obj, "MaxActivationDistance")})
        elseif c == "Tool" then
            table.insert(tools, {name=obj.Name, path=p})
        elseif c == "ScreenGui" or c == "Frame" or c == "TextButton" or c == "TextLabel" then
            table.insert(guis, {name=obj.Name, type=c, path=p, text=safe(obj, "Text") or "", visible=safe(obj, "Visible")})
        elseif c == "SpecialMesh" then
            local mid = safe(obj, "MeshId")
            if mid and mid ~= "" then table.insert(assets, {name=obj.Name, type="Mesh", id=mid, path=p}) end
        elseif c == "Animation" then
            local aid = safe(obj, "AnimationId")
            if aid and aid ~= "" then table.insert(assets, {name=obj.Name, type="Animation", id=aid, path=p}) end
        elseif c == "Sound" then
            local sid = safe(obj, "SoundId")
            if sid and sid ~= "" then table.insert(assets, {name=obj.Name, type="Sound", id=sid, path=p}) end
        elseif c == "Part" or c == "MeshPart" then
            local anchored = safe(obj, "Anchored")
            local canCollide = safe(obj, "CanCollide")
            local trans = safe(obj, "Transparency") or 0
            table.insert(parts, {name=obj.Name, path=p, anchored=anchored, canCollide=canCollide})
            if anchored == false then addVuln("LOW", "UNANCHORED", obj.Name, p) end
            if canCollide == false and trans >= 0.5 then addVuln("MED", "NOCLIP", obj.Name, p) end
        end
    end

    -- Tags
    if settings.SCAN_TAGS then
        statusLabel.Text = "Pass 2: Tags..."
        pcall(function()
            for _, obj in pairs(game:GetDescendants()) do
                local ok, tags = pcall(function() return CollectionService:GetTags(obj) end)
                if ok then
                    for _, tag in ipairs(tags) do
                        tagMap[tag] = (tagMap[tag] or 0) + 1
                    end
                end
            end
        end)
    end

    statusLabel.Text = "Building output..."
    w("============================================================")
    w("ROBLOX RECON v5 - " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("Place: " .. placeId .. " | Mode: " .. settings.MODE)
    w("Total instances: " .. totalCount)
    w("============================================================")
    w("")

    -- Hierarchy
    if settings.SCAN_HIERARCHY then
        w("=== HIERARCHY ===")
        local function prHier(obj, indent, maxD)
            if indent > maxD then return end
            local ind = string.rep("  ", indent)
            w(ind .. cn(obj) .. " | " .. obj.Name .. " (" .. #obj:GetChildren() .. ")")
            for i, ch in ipairs(obj:GetChildren()) do
                if i <= 150 then prHier(ch, indent + 1, maxD) end
            end
        end
        prHier(game, 0, settings.HIERARCHY_DEPTH)
        w("")
    end

    -- Scripts
    if settings.SCAN_SCRIPTS then
        w("=== SCRIPTS (" .. #scripts .. ") ===")
        for _, s in ipairs(scripts) do
            local lc = select(2, s.src:gsub("\n", "\n"))
            w(s.type .. " | " .. s.name .. " | " .. lc .. " lines | " .. s.path)
            if #s.src > 0 and settings.MAX_SOURCE_CHARS > 0 and #s.src <= settings.MAX_SOURCE_CHARS then
                w(string.sub(s.src, 1, 3000))
                w("")
            end
        end
        w("")
    end

    -- Remotes
    if settings.SCAN_REMOTES then
        w("=== REMOTES (" .. #remotes .. ") ===")
        for _, r in ipairs(remotes) do
            w(r.type .. " | " .. r.name .. " | Parent: " .. tostring(r.parent) .. " | " .. r.path)
        end
        w("")
    end

    -- Prompts
    if settings.SCAN_PROMPTS then
        w("=== PROMPTS (" .. #prompts .. ") ===")
        for _, pr in ipairs(prompts) do
            w(pr.name .. " | " .. tostring(pr.action) .. " | Dist: " .. tostring(pr.dist) .. " | " .. pr.path)
        end
        w("")
    end

    -- Tools
    if settings.SCAN_TOOLS then
        w("=== TOOLS (" .. #tools .. ") ===")
        for _, t in ipairs(tools) do w(t.name .. " | " .. t.path) end
        w("")
    end

    -- GUI
    if settings.SCAN_GUI then
        w("=== GUI (" .. #guis .. ") ===")
        for _, g in ipairs(guis) do
            if g.text ~= "" or g.type == "ScreenGui" then
                w(g.type .. " | " .. g.name .. " | " .. g.text:sub(1, 80) .. " | " .. g.path)
            end
        end
        w("")
    end

    -- Assets
    if settings.SCAN_ASSETS then
        w("=== ASSETS (" .. #assets .. ") ===")
        for _, a in ipairs(assets) do w(a.type .. " | " .. a.name .. " -> " .. a.id) end
        w("")
    end

    -- Security / Parts
    if settings.SCAN_PARTS then
        w("=== SECURITY ===")
        local unanchored, noclip = 0, 0
        for _, p in ipairs(parts) do
            if p.anchored == false then unanchored = unanchored + 1 end
            if p.canCollide == false then noclip = noclip + 1 end
        end
        w("Parts: " .. #parts .. " | Unanchored: " .. unanchored .. " | NoCollide: " .. noclip)
        w("")
    end

    -- Tags
    if settings.SCAN_TAGS then
        w("=== TAGS ===")
        for tag, cnt in pairs(tagMap) do w(tag .. ": " .. cnt) end
        w("")
    end

    -- Players
    if settings.SCAN_PLAYERS then
        w("=== PLAYERS ===")
        for _, plr in ipairs(Players:GetPlayers()) do
            w(plr.Name .. " (ID:" .. plr.UserId .. ")")
        end
        w("")
    end

    -- Vulnerabilities
    w("=== VULNERABILITIES (" .. vulnCount .. ") ===")
    for _, v in ipairs(vulns) do w(v) end
    w("")
    w("=== COMPLETE " .. os.date() .. " ===")

    -- Save
    local report = table.concat(out, "\n")
    saveFile(fileName, report)
    pcall(function() if setclipboard then setclipboard(report) end end)

    statusLabel.Text = "DONE! Saved: " .. fileName .. " | Vulns: " .. vulnCount
    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    startBtn.Text = "DONE"
    startBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

    -- Destroy GUI after delay
    wait(3)
    gui:Destroy()
end)

print("Recon v5 loaded. Tap START to begin.")
