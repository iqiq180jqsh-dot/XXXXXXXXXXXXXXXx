local library = { _Tabs = {}, _Pages = {} }
local services = setmetatable({}, {__index = function(_, k) return game:GetService(k) end})
local players, runService, uis, ts = services.Players, services.RunService, services.UserInputService, services.TweenService
local lp = players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = lp:WaitForChild("PlayerGui", 15) or game:GetService("CoreGui")
local vu = game:GetService("VirtualUser")

local Settings = {
    SelectedPlayer = nil,
    AimbotEnabled = false,
    AutoSkill = false,
    AutoGlide = false,
    GlideSpeed = 400,
    CurrentTween = nil
}

-- [[ 1. UI 拖動功能 ]]
function library:AddDrag(obj)
    local dragging, dragStart, startPos
    obj.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = true; dragStart = input.Position; startPos = obj.Position
        end
    end)
    uis.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    uis.InputEnded:Connect(function() dragging = false end)
end

function library.new()
    local sg = Instance.new("ScreenGui", playerGui); sg.Name = "BF_NoTransform_V47"; sg.ResetOnSpawn = false
    local Main = Instance.new("Frame", sg); Main.Size = UDim2.new(0, 420, 0, 500); Main.Position = UDim2.new(0.5, -210, 0.5, -250); Main.BackgroundColor3 = Color3.fromRGB(10, 10, 15); Instance.new("UICorner", Main)
    local Header = Instance.new("Frame", Main); Header.Size = UDim2.new(1, 0, 0, 40); Header.BackgroundColor3 = Color3.fromRGB(60, 0, 80); library:AddDrag(Main)
    local Title = Instance.new("TextLabel", Header); Title.Size = UDim2.new(1, 0, 1, 0); Title.Text = "BF 獵殺 (屏蔽 V 鍵變身版)"; Title.TextColor3 = Color3.new(1, 1, 1); Title.BackgroundTransparency = 1; Title.TextSize = 18
    local Scroll = Instance.new("ScrollingFrame", Main); Scroll.Size = UDim2.new(1, -20, 1, -60); Scroll.Position = UDim2.new(0, 10, 0, 50); Scroll.BackgroundTransparency = 1; Scroll.AutomaticCanvasSize = "Y"; Scroll.ScrollBarThickness = 2
    Instance.new("UIListLayout", Scroll).Padding = UDim.new(0, 10)
    return Scroll
end

local container = library.new()

-- [[ 2. 玩家列表 ]]
local targetLabel = Instance.new("TextLabel", container); targetLabel.Size = UDim2.new(1, 0, 0, 30); targetLabel.Text = "目標: 無"; targetLabel.TextColor3 = Color3.new(1, 1, 0); targetLabel.BackgroundTransparency = 1
local playerList = Instance.new("ScrollingFrame", container); playerList.Size = UDim2.new(1, 0, 0, 120); playerList.BackgroundColor3 = Color3.fromRGB(20, 20, 25); playerList.AutomaticCanvasSize = "Y"
Instance.new("UIListLayout", playerList)

local function refresh()
    for _, v in pairs(playerList:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    for _, p in pairs(players:GetPlayers()) do
        if p ~= lp then
            local b = Instance.new("TextButton", playerList); b.Size = UDim2.new(1, -10, 0, 25); b.Text = p.DisplayName; b.BackgroundColor3 = Color3.fromRGB(40, 40, 50); b.TextColor3 = Color3.new(1,1,1)
            b.MouseButton1Click:Connect(function() Settings.SelectedPlayer = p; targetLabel.Text = "已鎖定: " .. p.DisplayName end)
        end
    end
end
refresh()
local refBtn = Instance.new("TextButton", container); refBtn.Size = UDim2.new(1, 0, 0, 30); refBtn.Text = "🔄 刷新名單"; refBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 150); refBtn.TextColor3 = Color3.new(1, 1, 1)
refBtn.MouseButton1Click:Connect(refresh)

-- [[ 3. 高速滑行與秒停 ]]
local function SmoothGlide()
    if not Settings.AutoGlide or not Settings.SelectedPlayer then
        if Settings.CurrentTween then Settings.CurrentTween:Cancel(); Settings.CurrentTween = nil end
        return
    end
    local targetChar = Settings.SelectedPlayer.Character
    if targetChar and targetChar:FindFirstChild("HumanoidRootPart") and lp.Character:FindFirstChild("HumanoidRootPart") then
        local targetPos = (targetChar.HumanoidRootPart.CFrame * CFrame.new(0, 5, 4)).Position
        local distance = (lp.Character.HumanoidRootPart.Position - targetPos).Magnitude
        if distance > 3 then
            local duration = distance / Settings.GlideSpeed
            if Settings.CurrentTween then Settings.CurrentTween:Cancel() end
            Settings.CurrentTween = ts:Create(lp.Character.HumanoidRootPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos, targetChar.HumanoidRootPart.Position)})
            Settings.CurrentTween:Play()
        end
    end
end

-- [[ 4. 極速連招 (已移除 V 鍵) ]]
local function FastSkillNoV(tool)
    if not tool or not Settings.AutoSkill then return end
    lp.Character.Humanoid:EquipTool(tool)
    task.wait(0.05) 
    
    -- 這裡只保留 Z, X, C，移除了 V 鍵防止誤觸變身
    local keys = {"z", "x", "c"} 
    for _, k in ipairs(keys) do
        if not Settings.AutoSkill then break end
        vu:CaptureController()
        vu:SetKeyDown(k)
        task.wait(0.02)
        vu:SetKeyUp(k)
    end
end

-- [[ 5. UI 按鈕 ]]
local function addToggle(txt, key)
    local b = Instance.new("TextButton", container); b.Size = UDim2.new(1, 0, 0, 45); b.BackgroundColor3 = Color3.fromRGB(40, 40, 50); b.Text = txt..": 關"; b.TextColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        b.Text = txt .. (Settings[key] and ": 開" or ": 關")
        b.BackgroundColor3 = Settings[key] and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 40, 50)
        if key == "AutoGlide" and not Settings[key] then
            if Settings.CurrentTween then Settings.CurrentTween:Cancel(); Settings.CurrentTween = nil end
        end
    end)
end

addToggle("啟動高速滑行", "AutoGlide")
addToggle("鏡頭死鎖目標", "AimbotEnabled")
addToggle("自動極速連招 (不按V鍵)", "AutoSkill")

-- [[ 6. 核心循環 ]]
runService.RenderStepped:Connect(function()
    if Settings.AimbotEnabled and Settings.SelectedPlayer then
        pcall(function() camera.CFrame = CFrame.new(camera.CFrame.Position, Settings.SelectedPlayer.Character.HumanoidRootPart.Position) end)
    end
end)

task.spawn(function()
    while task.wait(0.05) do pcall(SmoothGlide) end
end)

task.spawn(function()
    while task.wait(0.2) do
        if Settings.AutoSkill and Settings.SelectedPlayer then
            pcall(function()
                local weaponTypes = {"Blox Fruit", "Melee", "Sword", "Gun"}
                for _, wType in ipairs(weaponTypes) do
                    local foundTool = nil
                    for _, t in pairs(lp.Backpack:GetChildren()) do
                        if t:IsA("Tool") and (t.ToolTip:find(wType) or t.Name:find(wType)) then
                            foundTool = t break
                        end
                    end
                    if foundTool then FastSkillNoV(foundTool) end
                    if not Settings.AutoSkill then break end
                end
            end)
        end
    end
end)
