--// Gnuhp Rainbow + Camlock Smooth + Auto Hitbox Invisible
--// By NguyenHoangPhung

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

getgenv().LockOn = false
getgenv().SoftAim = false
getgenv().Target = nil

-- Cấu hình hitbox
local HITBOX_SIZE = Vector3.new(20,20,20) -- vùng auto dính

------------------------------------------------
-- UI giữa màn hình
------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GnuhpUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 90)
Frame.Position = UDim2.new(0.5, -100, 0.5, -45) -- GIỮA MÀN HÌNH
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BackgroundTransparency = 0.2
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

-- Rainbow Lock
local LockButton = Instance.new("TextButton")
LockButton.Size = UDim2.new(0, 180, 0, 30)
LockButton.Position = UDim2.new(0.5, -90, 0, 8)
LockButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
LockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LockButton.TextScaled = true
LockButton.Font = Enum.Font.GothamBold
LockButton.Text = "Rainbow Lock (OFF)"
LockButton.Parent = Frame
LockButton.BorderSizePixel = 0
Instance.new("UICorner", LockButton).CornerRadius = UDim.new(0, 8)

-- Soft Aim
local SoftButton = Instance.new("TextButton")
SoftButton.Size = UDim2.new(0, 180, 0, 30)
SoftButton.Position = UDim2.new(0.5, -90, 0, 48)
SoftButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
SoftButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SoftButton.TextScaled = true
SoftButton.Font = Enum.Font.GothamBold
SoftButton.Text = "Soft Aim (OFF)"
SoftButton.Parent = Frame
SoftButton.BorderSizePixel = 0
Instance.new("UICorner", SoftButton).CornerRadius = UDim.new(0, 8)

-- Rainbow text effect cho cả 2 nút
task.spawn(function()
    local hue = 0
    while task.wait(0.05) do
        hue = (hue + 2) % 360
        local color = Color3.fromHSV(hue/360,1,1)
        LockButton.TextColor3 = color
        SoftButton.TextColor3 = color
    end
end)

------------------------------------------------
-- Helper: thêm / xoá hitbox vô hình
------------------------------------------------
local function addInvisibleHitbox(target)
    if not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = target.Character.HumanoidRootPart
    if hrp:FindFirstChild("LockHitbox") then return end -- tránh trùng

    local box = Instance.new("Part")
    box.Name = "LockHitbox"
    box.Size = HITBOX_SIZE
    box.Transparency = 1 -- hoàn toàn vô hình
    box.CanCollide = false
    box.Massless = true
    box.Anchored = false
    box.Parent = hrp

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hrp
    weld.Part1 = box
    weld.Parent = box

    -- highlight đỏ để biết đang lock ai
    local hl = Instance.new("Highlight")
    hl.Name = "LockHL"
    hl.FillColor = Color3.fromRGB(255,0,0)
    hl.OutlineColor = Color3.fromRGB(255,0,0)
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0
    hl.Adornee = target.Character
    hl.Parent = target.Character
end

local function removeInvisibleHitbox(target)
    if not target or not target.Character then return end
    local c = target.Character
    if c:FindFirstChild("LockHL") then c.LockHL:Destroy() end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:FindFirstChild("LockHitbox") then
        hrp.LockHitbox:Destroy()
    end
end

------------------------------------------------
-- Find closest target
------------------------------------------------
local function getClosestToCenter()
    local target, shortest = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") 
        and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if dist < shortest then
                    shortest, target = dist, plr
                end
            end
        end
    end
    return target
end

------------------------------------------------
-- Aim loop (Smooth camlock)
------------------------------------------------
RunService.RenderStepped:Connect(function()
    if getgenv().Target and getgenv().Target.Character and getgenv().Target.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = getgenv().Target.Character.HumanoidRootPart
        if getgenv().LockOn or getgenv().SoftAim then
            -- Smooth camera hướng về rún
            local goal = CFrame.new(Camera.CFrame.Position, hrp.Position)
            Camera.CFrame = Camera.CFrame:Lerp(goal, 0.25)

            if getgenv().LockOn and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                -- Tele mượt hơn (dính theo sau)
                local myhrp = LocalPlayer.Character.HumanoidRootPart
                myhrp.CFrame = myhrp.CFrame:Lerp(hrp.CFrame * CFrame.new(0,0,3), 0.3)
            end
        end
    end
end)

------------------------------------------------
-- Buttons
------------------------------------------------
LockButton.MouseButton1Click:Connect(function()
    getgenv().LockOn = not getgenv().LockOn
    getgenv().SoftAim = false
    if getgenv().LockOn then
        getgenv().Target = getClosestToCenter()
        if getgenv().Target then
            addInvisibleHitbox(getgenv().Target)
        end
        LockButton.Text = "Rainbow Lock (ON)"
        SoftButton.Text = "Soft Aim (OFF)"
    else
        if getgenv().Target then removeInvisibleHitbox(getgenv().Target) end
        getgenv().Target = nil
        LockButton.Text = "Rainbow Lock (OFF)"
    end
end)

SoftButton.MouseButton1Click:Connect(function()
    getgenv().SoftAim = not getgenv().SoftAim
    getgenv().LockOn = false
    if getgenv().SoftAim then
        getgenv().Target = getClosestToCenter()
        if getgenv().Target then
            addInvisibleHitbox(getgenv().Target)
        end
        SoftButton.Text = "Soft Aim (ON)"
        LockButton.Text = "Rainbow Lock (OFF)"
    else
        if getgenv().Target then removeInvisibleHitbox(getgenv().Target) end
        getgenv().Target = nil
        SoftButton.Text = "Soft Aim (OFF)"
    end
end)
