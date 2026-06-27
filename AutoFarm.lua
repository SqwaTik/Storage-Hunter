--[[ AutoFarm v2 — Universal for Auction Tycoon ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

-- Settings
local S = {
    AutoBid = false, AutoCollectCoins = false, AutoBuyout = false,
    BidAmount = 100, BidDelay = 3,
    AutoStock = false, AutoCollectEarnings = false, StockDelay = 5,
    AutoSellPawn = false, PawnSellDelay = 5,
    AutoDaily = false, DailyDelay = 60,
    AutoUpgrade = false, UpgradeDelay = 10,
    AutoQuest = false, QuestDelay = 15,
    AutoExpandPlot = false, AutoBuild = false, ExpandDelay = 30,
    AutoFish = false, FishDelay = 8,
    AutoLuckyPotion = false, PotionDelay = 300,
    AutoVehicleIncome = false, VehicleDelay = 60,
}

local guiEnabled = false
local RC = {}
local coroutines = {}

local function scan()
    local events = RS:FindFirstChild("Events")
    if not events then return end
    for _, folder in ipairs(events:GetChildren()) do
        for _, obj in ipairs(folder:GetChildren()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                RC[folder.Name .. "." .. obj.Name] = obj
                RC[obj.Name] = obj
            end
            for _, sub in ipairs(obj:GetChildren()) do
                if sub:IsA("RemoteEvent") or sub:IsA("RemoteFunction") then
                    RC[folder.Name .. "." .. obj.Name .. "." .. sub.Name] = sub
                    RC[obj.Name .. "." .. sub.Name] = sub
                    RC[sub.Name] = sub
                end
            end
        end
    end
    local n = 0; for _ in pairs(RC) do n = n + 1 end
    print("[Farm] Found " .. n .. " remotes")
end

local function fire(name, ...)
    local ev = RC[name]
    if not ev then return end
    local ok, err = pcall(function()
        if ev:IsA("RemoteEvent") then ev:FireServer(...)
        else return ev:InvokeServer(...) end
    end)
    return ok, err
end

local function has(name)
    return RC[name] ~= nil
end

-- GUI Builder
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFarmGUI"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = pg
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 600, 0, 400)
main.Position = UDim2.new(0.5, -300, 0.5, -200)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
main.BackgroundTransparency = 0.1
main.BorderSizePixel = 0
main.Parent = gui
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 12)
    c.Parent = main
end

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 36)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
title.BackgroundTransparency = 0.3
title.BorderSizePixel = 0
title.Text = "AutoFarm v2"
title.TextColor3 = Color3.fromRGB(220, 220, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.Parent = main
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 12)
    c.Parent = title
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(60, 60, 100)
    s.Thickness = 1
    s.Parent = title
end

local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1, 0, 0, 36)
tabFrame.Position = UDim2.new(0, 0, 0, 36)
tabFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
tabFrame.BorderSizePixel = 0
tabFrame.Parent = main

local tabs = {"Auction", "Shop", "Pawn", "Plot", "Other"}
local tabButtons = {}
local tabPanels = {}

local function makeTab(name, idx)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 1, 0)
    btn.Position = UDim2.new(0, (idx-1)*120, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(180, 180, 200)
    btn.TextSize = 14
    btn.Font = Enum.Font.Gotham
    btn.Parent = tabFrame
    
    local panel = Instance.new("ScrollingFrame")
    panel.Size = UDim2.new(1, -10, 0, 300)
    panel.Position = UDim2.new(0, 5, 0, 78)
    panel.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    panel.BackgroundTransparency = 1
    panel.BorderSizePixel = 0
    panel.ScrollBarThickness = 4
    panel.CanvasSize = UDim2.new(0, 0, 0, 0)
    panel.Visible = (idx == 1)
    panel.Parent = main
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = panel
    
    btn.MouseButton1Click:Connect(function()
        for i, b in ipairs(tabButtons) do
            b.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
            tabPanels[i].Visible = false
        end
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
        panel.Visible = true
    end)
    
    table.insert(tabButtons, btn)
    table.insert(tabPanels, panel)
    return panel
end

local function makeToggle(parent, name, key)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, 40)
    f.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
    f.BackgroundTransparency = 0.2
    f.BorderSizePixel = 0
    f.Parent = parent
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = f
    end
    
    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(0.7, 0, 1, 0)
    lb.Position = UDim2.new(0, 10, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text = name
    lb.TextColor3 = Color3.fromRGB(200, 200, 220)
    lb.TextSize = 14
    lb.Font = Enum.Font.Gotham
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = f
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 80, 0, 30)
    btn.Position = UDim2.new(1, -90, 0.5, -15)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    btn.BorderSizePixel = 0
    btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(200, 80, 80)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.Parent = f
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = btn
    end
    
    btn.MouseButton1Click:Connect(function()
        S[key] = not S[key]
        if S[key] then
            btn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
            btn.Text = "ON"
            btn.TextColor3 = Color3.fromRGB(220, 255, 220)
        else
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
            btn.Text = "OFF"
            btn.TextColor3 = Color3.fromRGB(200, 80, 80)
        end
    end)
    return btn
end

local function makeInput(parent, name, key, placeholder, default)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, 40)
    f.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
    f.BackgroundTransparency = 0.2
    f.BorderSizePixel = 0
    f.Parent = parent
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = f
    end
    
    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(0.4, 0, 1, 0)
    lb.Position = UDim2.new(0, 10, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text = name
    lb.TextColor3 = Color3.fromRGB(200, 200, 220)
    lb.TextSize = 14
    lb.Font = Enum.Font.Gotham
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = f
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 100, 0, 30)
    box.Position = UDim2.new(1, -110, 0.5, -15)
    box.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    box.BorderSizePixel = 0
    box.Text = tostring(S[key] or default)
    box.TextColor3 = Color3.fromRGB(220, 220, 255)
    box.TextSize = 13
    box.Font = Enum.Font.Gotham
    box.PlaceholderText = placeholder or ""
    box.Parent = f
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = box
    end
    
    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val then S[key] = val end
    end)
    return box
end

-- Build tabs
local panelAuction = makeTab("Auction", 1)
makeToggle(panelAuction, "Auto Bid", "AutoBid")
makeToggle(panelAuction, "Auto Collect Coins", "AutoCollectCoins")
makeInput(panelAuction, "Bid Amount ($)", "BidAmount", "Amount per bid", 100)
makeInput(panelAuction, "Bid Delay (sec)", "BidDelay", "Delay between bids", 3)

local panelShop = makeTab("Shop", 2)
makeToggle(panelShop, "Auto Stock Shelves", "AutoStock")
makeToggle(panelShop, "Auto Collect Earnings", "AutoCollectEarnings")
makeInput(panelShop, "Stock Delay (sec)", "StockDelay", "Delay between stocks", 5)

local panelPawn = makeTab("Pawn", 3)
makeToggle(panelPawn, "Auto Sell Pawn Items", "AutoSellPawn")
makeInput(panelPawn, "Sell Delay (sec)", "PawnSellDelay", "Delay between sells", 5)

local panelPlot = makeTab("Plot", 4)
makeToggle(panelPlot, "Auto Expand Plot", "AutoExpandPlot")
makeToggle(panelPlot, "Auto Build", "AutoBuild")
makeInput(panelPlot, "Expand Delay (sec)", "ExpandDelay", "Delay between expands", 30)

local panelOther = makeTab("Other", 5)
makeToggle(panelOther, "Auto Daily Reward", "AutoDaily")
makeInput(panelOther, "Daily Delay (sec)", "DailyDelay", "Delay between claims", 60)
makeToggle(panelOther, "Auto Upgrades", "AutoUpgrade")
makeInput(panelOther, "Upgrade Delay (sec)", "UpgradeDelay", "Delay between upgrades", 10)
makeToggle(panelOther, "Auto Quests", "AutoQuest")
makeInput(panelOther, "Quest Delay (sec)", "QuestDelay", "Delay between quests", 15)
makeToggle(panelOther, "Auto Fish", "AutoFish")
makeInput(panelOther, "Fish Delay (sec)", "FishDelay", "Delay between casts", 8)
makeToggle(panelOther, "Auto Lucky Potion", "AutoLuckyPotion")
makeInput(panelOther, "Potion Delay (sec)", "PotionDelay", "Delay between potions", 300)
makeToggle(panelOther, "Auto Vehicle Income", "AutoVehicleIncome")
makeInput(panelOther, "Vehicle Delay (sec)", "VehicleDelay", "Delay between collections", 60)

-- Note
local note = Instance.new("TextLabel")
note.Size = UDim2.new(1, -20, 0, 24)
note.Position = UDim2.new(0, 10, 0, 376)
note.BackgroundTransparency = 1
note.Text = "RightShift — toggle GUI | Events scanned automatically"
note.TextColor3 = Color3.fromRGB(140, 140, 160)
note.TextSize = 11
note.Font = Enum.Font.Gotham
note.TextWrapped = true
note.Parent = main

-- Update canvas sizes
local function updateCanvas()
    for _, panel in ipairs(tabPanels) do
        local layout = panel:FindFirstChildOfClass("UIListLayout")
        if layout then
            panel.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        end
    end
end
task.spawn(function() task.wait(0.1) updateCanvas() end)

-- Scan remotes
scan()
print("[Farm] GUI ready. Press RightShift to toggle.")

-- Module coroutines
local function runModule(name, enabledKey, fn)
    if coroutines[name] then
        coroutines[name]:Cancel()
        coroutines[name] = nil
    end
    if S[enabledKey] then
        coroutines[name] = task.spawn(fn)
    end
end

local function startStopModules()
    runModule("auctionBid", "AutoBid", function()
        while S.AutoBid do
            task.wait(S.BidDelay)
            if has("Bid") then
                fire("Bid", S.BidAmount)
            else
                local ev = RC["Auctions.Bid"] or RC["Auction.Bid"]
                if ev then fire(ev, S.BidAmount) end
            end
        end
    end)
    
    runModule("auctionCoins", "AutoCollectCoins", function()
        while S.AutoCollectCoins do
            task.wait(10)
            fire("CollectEarnings") or fire("Auction.CollectEarnings") or fire("Auctions.CollectEarnings")
        end
    end)
    
    runModule("stock", "AutoStock", function()
        while S.AutoStock do
            task.wait(S.StockDelay)
            fire("Stock") or fire("Shop.Stock")
        end
    end)
    
    runModule("shopEarnings", "AutoCollectEarnings", function()
        while S.AutoCollectEarnings do
            task.wait(10)
            fire("CollectEarnings") or fire("Shop.CollectEarnings")
        end
    end)
    
    runModule("pawnSell", "AutoSellPawn", function()
        while S.AutoSellPawn do
            task.wait(S.PawnSellDelay)
            if has("SellItem") then
                fire("SellItem")
            else
                fire("PawnShop.SellItem")
            end
        end
    end)
    
    runModule("daily", "AutoDaily", function()
        while S.AutoDaily do
            task.wait(S.DailyDelay)
            fire("ClaimReward") or fire("DailyReward.ClaimReward")
        end
    end)
    
    runModule("upgrade", "AutoUpgrade", function()
        while S.AutoUpgrade do
            task.wait(S.UpgradeDelay)
            fire("BuyUpgrade") or fire("Upgrades.BuyUpgrade")
        end
    end)
    
    runModule("quest", "AutoQuest", function()
        while S.AutoQuest do
            task.wait(S.QuestDelay)
            fire("ClaimQuest") or fire("Quests.ClaimQuest")
        end
    end)
    
    runModule("expand", "AutoExpandPlot", function()
        while S.AutoExpandPlot do
            task.wait(S.ExpandDelay)
            fire("Expand") or fire("Plot.Expand")
        end
    end)
    
    runModule("build", "AutoBuild", function()
        while S.AutoBuild do
            task.wait(5)
            local walls = {"PlaceWall", "PlaceFloor", "PlaceRoof", "PlaceWindow", "PlaceDoor"}
            for _, cmd in ipairs(walls) do
                if not S.AutoBuild then break end
                fire(cmd) or fire("Plot." .. cmd)
                task.wait(1)
            end
        end
    end)
    
    runModule("fish", "AutoFish", function()
        while S.AutoFish do
            task.wait(S.FishDelay)
            fire("Fish") or fire("Fishing.Fish")
        end
    end)
    
    runModule("potion", "AutoLuckyPotion", function()
        while S.AutoLuckyPotion do
            task.wait(S.PotionDelay)
            fire("UsePotion") or fire("Misc.UsePotion")
        end
    end)
    
    runModule("vehicle", "AutoVehicleIncome", function()
        while S.AutoVehicleIncome do
            task.wait(S.VehicleDelay)
            fire("SpawnVehicle") or fire("Vehicles.SpawnVehicle")
        end
    end)
end

-- Watch settings changes (re-scan every toggle)
local oldS = {}
for k, v in pairs(S) do oldS[k] = v end

task.spawn(function()
    while task.wait(0.5) do
        for k, v in pairs(S) do
            if oldS[k] ~= v then
                oldS[k] = v
                startStopModules()
                break
            end
        end
    end
end)

-- Initial start
task.wait(1)
startStopModules()

-- Keybind
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        guiEnabled = not guiEnabled
        gui.Enabled = guiEnabled
    end
end)

print("[Farm] AutoFarm v2 loaded successfully")
