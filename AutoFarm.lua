--[[ AutoFarm v2 — Universal for Auction Tycoon ]]
local ok, err = pcall(function()
    local Players = (game:FindService and game:FindService("Players")) or game:GetService("Players")
    local RS = (game:FindService and game:FindService("ReplicatedStorage")) or game:GetService("ReplicatedStorage")
    local UIS = (game:FindService and game:FindService("UserInputService")) or game:GetService("UserInputService")
    local player = Players.LocalPlayer
    if not player then task.wait(1); player = Players.LocalPlayer end
    local pg = player:WaitForChild("PlayerGui", 10)
    if not pg then return end

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
    local function id(...) return (...) end

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
        local r = RC[name]
        if not r then return false end
        if r:IsA("RemoteEvent") then
            pcall(r.FireServer, r, ...)
            return true
        elseif r:IsA("RemoteFunction") then
            pcall(r.InvokeServer, r, ...)
            return true
        end
        return false
    end

    -- GUI
    local gui = Instance.new("ScreenGui")
    gui.Name = "AutoFarmGUI"
    gui.ResetOnSpawn = false
    gui.Parent = pg

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 350, 0, 500)
    frame.Position = UDim2.new(0.5, -175, 0.5, -250)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Parent = gui
    gui.Enabled = false

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "AutoFarm v2"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextScaled = true
    title.Parent = frame

    -- Tabs
    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, 0, 0, 35)
    tabFrame.Position = UDim2.new(0, 0, 0, 35)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Parent = frame

    local tabs = {"Auction", "Shop", "Pawn", "Plot", "Other"}
    local currentTab = nil
    local scrollFrame
    local tabButtons = {}
    local function switchTab(name)
        if scrollFrame then scrollFrame:Destroy() end
        scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Size = UDim2.new(1, -10, 1, -85)
        scrollFrame.Position = UDim2.new(0, 5, 0, 75)
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.BorderSizePixel = 0
        scrollFrame.ScrollBarThickness = 4
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        scrollFrame.Parent = frame
        currentTab = name

        local items = {}
        if name == "Auction" then
            items = {{"AutoBid", "Auto Bid"}, {"BidAmount", "Bid Amount"}, {"BidDelay", "Bid Delay (s)"}, {"AutoCollectCoins", "Collect Coins"}, {"AutoBuyout", "Auto Buyout"}}
        elseif name == "Shop" then
            items = {{"AutoStock", "Auto Stock"}, {"StockDelay", "Stock Delay (s)"}, {"AutoCollectEarnings", "Collect Earnings"}}
        elseif name == "Pawn" then
            items = {{"AutoSellPawn", "Auto Sell Pawn"}, {"PawnSellDelay", "Sell Delay (s)"}}
        elseif name == "Plot" then
            items = {{"AutoExpandPlot", "Expand Plot"}, {"ExpandDelay", "Expand Delay (s)"}, {"AutoBuild", "Auto Build"}}
        elseif name == "Other" then
            items = {{"AutoDaily", "Auto Daily"}, {"DailyDelay", "Daily Delay (s)"}, {"AutoUpgrade", "Auto Upgrade"}, {"UpgradeDelay", "Upgrade Delay (s)"}, {"AutoQuest", "Auto Quest"}, {"QuestDelay", "Quest Delay (s)"}, {"AutoFish", "Auto Fish"}, {"FishDelay", "Fish Delay (s)"}, {"AutoLuckyPotion", "Lucky Potion"}, {"PotionDelay", "Potion Delay (s)"}, {"AutoVehicleIncome", "Vehicle Income"}, {"VehicleDelay", "Vehicle Delay (s)"}}
        end

        local y = 0
        for _, item in ipairs(items) do
            local key = item[1]
            local label = item[2]
            if key:find("Delay") or key:find("Amount") then
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 35)
                row.Position = UDim2.new(0, 0, 0, y)
                row.BackgroundTransparency = 1
                row.Parent = scrollFrame

                local txt = Instance.new("TextLabel")
                txt.Size = UDim2.new(0.6, 0, 1, 0)
                txt.BackgroundTransparency = 1
                txt.Text = label
                txt.TextColor3 = Color3.fromRGB(200, 200, 200)
                txt.Font = Enum.Font.Gotham
                txt.TextSize = 14
                txt.TextXAlignment = Enum.TextXAlignment.Left
                txt.Parent = row

                local box = Instance.new("TextBox")
                box.Size = UDim2.new(0.35, 0, 0, 30)
                box.Position = UDim2.new(0.65, 0, 0, 2.5)
                box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                box.TextColor3 = Color3.fromRGB(255, 255, 255)
                box.Font = Enum.Font.Gotham
                box.TextSize = 14
                box.Text = tostring(S[key])
                box.Parent = row

                box.FocusLost:Connect(function(enter)
                    if enter then
                        local val = tonumber(box.Text)
                        if val then S[key] = val end
                        box.Text = tostring(S[key])
                    end
                end)

                y = y + 38
            else
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 35)
                row.Position = UDim2.new(0, 0, 0, y)
                row.BackgroundTransparency = 1
                row.Parent = scrollFrame

                local txt = Instance.new("TextLabel")
                txt.Size = UDim2.new(0.6, 0, 1, 0)
                txt.BackgroundTransparency = 1
                txt.Text = label
                txt.TextColor3 = Color3.fromRGB(200, 200, 200)
                txt.Font = Enum.Font.Gotham
                txt.TextSize = 14
                txt.TextXAlignment = Enum.TextXAlignment.Left
                txt.Parent = row

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0.35, 0, 0, 30)
                btn.Position = UDim2.new(0.65, 0, 0, 2.5)
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 14
                btn.Text = S[key] and "ON" or "OFF"
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                local function updateBtn()
                    btn.Text = S[key] and "ON" or "OFF"
                    btn.BackgroundColor3 = S[key] and Color3.fromRGB(40, 200, 40) or Color3.fromRGB(80, 80, 80)
                end
                updateBtn()
                btn.MouseButton1Click:Connect(function()
                    S[key] = not S[key]
                    updateBtn()
                end)
                btn.Parent = row

                y = y + 38
            end
        end
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, y + 10)
    end

    for i, tab in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.2, 0, 1, 0)
        btn.Position = UDim2.new(0.2 * (i - 1), 0, 0, 0)
        btn.BackgroundTransparency = 1
        btn.Text = tab
        btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.Parent = tabFrame
        tabButtons[tab] = btn
        btn.MouseButton1Click:Connect(function()
            for _, b in pairs(tabButtons) do b.TextColor3 = Color3.fromRGB(180, 180, 180) end
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            switchTab(tab)
        end)
    end
    switchTab("Auction")
    tabButtons["Auction"].TextColor3 = Color3.fromRGB(255, 255, 255)

    -- Modules
    local function startStopModules()
        for k, co in pairs(coroutines) do
            task.cancel(co)
            coroutines[k] = nil
        end
        for k, v in pairs(S) do
            if type(v) == "boolean" and v then
                if k == "AutoBid" then
                    coroutines[k] = task.spawn(function()
                        while S[k] do
                            task.wait(S.BidDelay)
                            fire("Bid") or fire("Auction.Bid")
                            for i = 1, 5 do fire("IncreaseBid") or fire("Auction.IncreaseBid") end
                        end
                    end)
                elseif k == "AutoCollectCoins" then
                    coroutines[k] = task.spawn(function()
                        while S[k] do
                            task.wait(5)
                            fire("CollectCoins") or fire("Auction.CollectCoins")
                        end
                    end)
                elseif k == "AutoBuyout" then
                    coroutines[k] = task.spawn(function()
                        while S[k] do
                            task.wait(S.BidDelay + 1)
                            fire("Buyout") or fire("Auction.Buyout")
                        end
                    end)
                elseif k == "AutoStock" then
                    coroutines[k] = task.spawn(function()
                        while S[k] do
                            task.wait(S.StockDelay)
                            fire("Stock") or fire("Shop.Stock")
                        end
                    end)
                elseif k == "AutoCollectEarnings" then
                    coroutines[k] = task.spawn(function()
                        while S[k] do
                            task.wait(5)
                            fire("CollectEarnings") or fire("Shop.CollectEarnings")
                        end
                    end)
                elseif k == "AutoSellPawn" then
                    coroutines[k] = task.spawn(function()
                        while S[k] do
                            task.wait(S.PawnSellDelay)
                            fire("SellPawn") or fire("Pawn.SellPawn")
                        end
                    end)
                elseif k == "AutoDaily" then
                    coroutines[k] = task.spawn(function()
                        while S[k] do
                            task.wait(S.DailyDelay)
                            fire("ClaimDaily") or fire("DailyReward.Claim")
                        end
                    end)
                elseif k == "AutoUpgrade" then
                    coroutines[k] = task.spawn(function()
                        while S[k] do
                            task.wait(S.UpgradeDelay)
                            fire("Upgrade") or fire("Upgrades.Upgrade")
                        end
                    end)
                elseif k == "AutoQuest" then
                    coroutines[k] = task.spawn(function()
                        while S[k] do
                            task.wait(S.QuestDelay)
                            fire("ClaimQuest") or fire("Quest.ClaimReward")
                            fire("StartQuest") or fire("Quest.StartQuest")
                        end
                    end)
                elseif k == "AutoExpandPlot" then
                    coroutines[k] = task.spawn(function()
                        while S[k] do
                            task.wait(S.ExpandDelay)
                            fire("ExpandPlot") or fire("Plot.Expand")
                        end
                    end)
                elseif k == "AutoBuild" then
                    coroutines[k] = task.spawn(function()
                        while S[k] do
                            task.wait(5)
                            fire("Build") or fire("Plot.Build")
                            fire("PlaceWall") or fire("Plot.PlaceWall")
                        end
                    end)
                elseif k == "AutoFish" then
                    coroutines[k] = task.spawn(function()
                        while S[k] do
                            task.wait(S.FishDelay)
                            fire("CastRod") or fire("Fishing.CastRod")
                            fire("ReelIn") or fire("
