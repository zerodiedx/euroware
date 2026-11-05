local HazeSource = game:HttpGet("https://raw.githubusercontent.com/ShaneDasPro/Roblox-HAZE-UI-LIBRARY/main/HazeUILibrary.luau")
HazeSource = HazeSource:gsub("%$hane", "euro")
HazeSource = HazeSource:gsub("Haze", "Euroware")
HazeSource = HazeSource:gsub("hologram", "https://discord.gg/8fjVDektPK")
HazeSource = HazeSource:gsub("Hologram", "https://discord.gg/8fjVDektPK")

local Haze = loadstring(HazeSource)()
Haze.ToggleKey = Enum.KeyCode.K

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local State = {
    flying = false, flySpeed = 60, flyVert = 1.5, flySmooth = 8,
    flyConn = nil, alignPos = nil, alignOri = nil,
    aimbot = false, aimPart = 'Head', aimFov = 150, aimSmooth = 0.15, aimConn = nil,
    hitbox = false, hitboxSize = 10, hitboxParts = {},
    esp = false, espBoxes = {}, espConn = nil,
    tracers = false, tracerLines = {}, tracerConn = nil,
    spin = false, spinSpeed = 50, spinConn = nil,
    noclip = false, noclipConn = nil, infJump = false,
    chatSpamEnabled = false, chatSpamMessage = "EuroWare on top!", chatSpamDelay = 1.5, chatSpamThread = nil,
}

local function getTargets()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = p.Character:FindFirstChildOfClass('Humanoid')
            if hum and hum.Health > 0 then table.insert(list, p) end
        end
    end
    return list
end

local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild('HumanoidRootPart')
    local hum = char:FindFirstChildOfClass('Humanoid')
    if not hrp or not hum then return end
    State.flying = true
    hum.PlatformStand = true
    local att0 = Instance.new('Attachment', hrp)
    att0.Name = 'FlyAtt0'
    local alignPos = Instance.new('AlignPosition')
    alignPos.Name = 'FlyAlignPos'
    alignPos.Attachment0 = att0
    alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
    alignPos.RigidityEnabled = false
    alignPos.MaxForce = 100000
    alignPos.MaxVelocity = State.flySpeed
    alignPos.Responsiveness = State.flySmooth
    alignPos.Position = hrp.Position
    alignPos.Parent = hrp
    State.alignPos = alignPos
    local alignOri = Instance.new('AlignOrientation')
    alignOri.Name = 'FlyAlignOri'
    alignOri.Attachment0 = att0
    alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOri.RigidityEnabled = false
    alignOri.MaxTorque = 100000
    alignOri.MaxAngularVelocity = 20
    alignOri.Responsiveness = State.flySmooth
    alignOri.CFrame = Camera.CFrame
    alignOri.Parent = hrp
    State.alignOri = alignOri
    State.flyConn = RunService.RenderStepped:Connect(function()
        if not State.flying or not hrp or not hrp.Parent then return end
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) * State.flyVert end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) * State.flyVert end
        local targetPos = hrp.Position + (dir.Magnitude > 0 and dir.Unit * 10 or Vector3.zero)
        alignPos.Position = targetPos
        alignPos.MaxVelocity = State.flySpeed
        alignPos.Responsiveness = State.flySmooth
        alignOri.CFrame = Camera.CFrame
        alignOri.Responsiveness = State.flySmooth
    end)
end

local function stopFly()
    State.flying = false
    if State.flyConn then State.flyConn:Disconnect(); State.flyConn = nil end
    if State.alignPos then State.alignPos:Destroy(); State.alignPos = nil end
    if State.alignOri then State.alignOri:Destroy(); State.alignOri = nil end
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild('HumanoidRootPart')
        if hrp then
            local att = hrp:FindFirstChild('FlyAtt0')
            if att then att:Destroy() end
        end
        local hum = char:FindFirstChildOfClass('Humanoid')
        if hum then hum.PlatformStand = false end
    end
end

local function startAimbot()
    State.aimbot = true
    State.aimConn = RunService.RenderStepped:Connect(function()
        if not State.aimbot then return end
        local closest, closestDist = nil, State.aimFov
        local mousePos = UserInputService:GetMouseLocation()
        for _, p in ipairs(getTargets()) do
            local part = p.Character:FindFirstChild(State.aimPart)
            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                    if dist < closestDist then closestDist = dist; closest = p end
                end
            end
        end
        if closest then
            local part = closest.Character:FindFirstChild(State.aimPart)
            if part then
                local goal = CFrame.lookAt(Camera.CFrame.Position, part.Position)
                Camera.CFrame = Camera.CFrame:Lerp(goal, State.aimSmooth)
            end
        end
    end)
end

local function stopAimbot()
    State.aimbot = false
    if State.aimConn then State.aimConn:Disconnect(); State.aimConn = nil end
end

local function clearHitboxFor(player)
    local box = State.hitboxParts[player]
    if box then box:Destroy(); State.hitboxParts[player] = nil end
end

local function applyHitboxFor(player)
    if player == LocalPlayer or not player.Character then return end
    local hrp = player.Character:FindFirstChild('HumanoidRootPart')
    if not hrp then return end
    clearHitboxFor(player)
    local box = Instance.new('Part')
    box.Name = 'EuroHitbox'
    box.Size = Vector3.new(State.hitboxSize, State.hitboxSize, State.hitboxSize)
    box.Color = Color3.fromRGB(0, 100, 255)
    box.Transparency = 0.7
    box.Material = Enum.Material.ForceField
    box.CanCollide = false
    box.CanQuery = true
    box.CanTouch = false
    box.Massless = true
    box.Anchored = false
    box.Parent = player.Character
    local weld = Instance.new('WeldConstraint')
    weld.Part0 = box
    weld.Part1 = hrp
    weld.Parent = box
    box.CFrame = hrp.CFrame
    State.hitboxParts[player] = box
end

local function enableHitbox()
    State.hitbox = true
    for _, p in ipairs(getTargets()) do applyHitboxFor(p) end
end

local function disableHitbox()
    State.hitbox = false
    for p in pairs(State.hitboxParts) do clearHitboxFor(p) end
end

local function startESP()
    State.esp = true
    local function makeLine()
        local line = Drawing.new('Line')
        line.Thickness = 2
        line.Color = Color3.fromRGB(0, 255, 0)
        line.Visible = false
        return line
    end
    State.espConn = RunService.RenderStepped:Connect(function()
        if not State.esp then return end
        for p, data in pairs(State.espBoxes) do
            if not p.Parent or not p.Character then
                for _, obj in pairs(data) do obj:Remove() end
                State.espBoxes[p] = nil
            end
        end
        for _, p in ipairs(getTargets()) do
            if not State.espBoxes[p] then
                State.espBoxes[p] = { Top = makeLine(), Bottom = makeLine(), Left = makeLine(), Right = makeLine(), Text = Drawing.new('Text') }
                local txt = State.espBoxes[p].Text
                txt.Size = 16; txt.Center = true; txt.Outline = true; txt.Color = Color3.fromRGB(0, 255, 0); txt.Visible = false
            end
            local data = State.espBoxes[p]
            local hrp = p.Character and p.Character:FindFirstChild('HumanoidRootPart')
            local hum = p.Character and p.Character:FindFirstChildOfClass('Humanoid')
            if hrp and hum then
                local hrpPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                    local height = (Camera.ViewportSize.Y / dist) * 1.5
                    local width = height * 0.6
                    local topLeft = Vector2.new(hrpPos.X - width/2, hrpPos.Y - height/2)
                    local bottomRight = Vector2.new(hrpPos.X + width/2, hrpPos.Y + height/2)
                    data.Top.From = topLeft; data.Top.To = Vector2.new(bottomRight.X, topLeft.Y)
                    data.Bottom.From = Vector2.new(topLeft.X, bottomRight.Y); data.Bottom.To = bottomRight
                    data.Left.From = topLeft; data.Left.To = Vector2.new(topLeft.X, bottomRight.Y)
                    data.Right.From = Vector2.new(bottomRight.X, topLeft.Y); data.Right.To = bottomRight
                    data.Text.Text = string.format("%s [%d]", p.Name, math.floor(hum.Health))
                    data.Text.Position = Vector2.new(hrpPos.X, topLeft.Y - 20)
                    for _, obj in pairs(data) do obj.Visible = true end
                else
                    for _, obj in pairs(data) do obj.Visible = false end
                end
            end
        end
    end)
end

local function stopESP()
    State.esp = false
    if State.espConn then State.espConn:Disconnect(); State.espConn = nil end
    for p, data in pairs(State.espBoxes) do 
        for _, obj in pairs(data) do obj:Remove() end
        State.espBoxes[p] = nil 
    end
end

local function startTracers()
    State.tracers = true
    State.tracerConn = RunService.RenderStepped:Connect(function()
        if not State.tracers then return end
        for _, p in ipairs(getTargets()) do
            local line = State.tracerLines[p]
            if not line then
                line = Drawing.new('Line')
                line.Thickness = 1; line.Color = Color3.fromRGB(255, 255, 255); line.Transparency = 0.7
                State.tracerLines[p] = line
            end
            local hrp = p.Character:FindFirstChild('HumanoidRootPart')
            if hrp then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                line.Visible = onScreen
                if onScreen then
                    line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    line.To = Vector2.new(pos.X, pos.Y)
                end
            end
        end
    end)
end

local function stopTracers()
    State.tracers = false
    if State.tracerConn then State.tracerConn:Disconnect(); State.tracerConn = nil end
    for p, line in pairs(State.tracerLines) do line:Remove(); State.tracerLines[p] = nil end
end

local function startSpin()
    State.spin = true
    State.spinConn = RunService.Heartbeat:Connect(function()
        if not State.spin then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild('HumanoidRootPart')
        if not hrp then return end
        local existing = hrp:FindFirstChild('SpinBot')
        if not existing then
            local bav = Instance.new('BodyAngularVelocity')
            bav.Name = 'SpinBot'; bav.AngularVelocity = Vector3.new(0, State.spinSpeed, 0)
            bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge); bav.P = 10000
            bav.Parent = hrp
        else
            existing.AngularVelocity = Vector3.new(0, State.spinSpeed, 0)
        end
    end)
end

local function stopSpin()
    State.spin = false
    if State.spinConn then State.spinConn:Disconnect(); State.spinConn = nil end
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild('HumanoidRootPart')
        if hrp then
            local bav = hrp:FindFirstChild('SpinBot')
            if bav then bav:Destroy() end
        end
    end
end

local function setNoclip(on)
    State.noclip = on
    if State.noclipConn then State.noclipConn:Disconnect(); State.noclipConn = nil end
    if on then
        State.noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA('BasePart') then p.CanCollide = false end
                end
            end
        end)
    end
end

local function startChatSpam()
    State.chatSpamEnabled = true
    if State.chatSpamThread then task.cancel(State.chatSpamThread) end
    State.chatSpamThread = task.spawn(function()
        while State.chatSpamEnabled do
            local msg = State.chatSpamMessage
            if msg and msg ~= "" then
                local chatService = game:GetService("TextChatService")
                if chatService.ChatVersion == Enum.ChatVersion.TextChatService then
                    local channel = chatService:FindFirstChild("TextChannels") and chatService.TextChannels:FindFirstChild("RBXGeneral")
                    if channel then channel:SendAsync(msg) end
                else
                    local oldChat = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                    if oldChat then oldChat.SayMessageRequest:FireServer(msg, "All") end
                end
            end
            task.wait(State.chatSpamDelay)
        end
    end)
end

local function stopChatSpam()
    State.chatSpamEnabled = false
    if State.chatSpamThread then task.cancel(State.chatSpamThread); State.chatSpamThread = nil end
end

local Window = Haze:CreateWindow({
    Title = "EuroWare",
    Size = UDim2.fromOffset(600, 500),
    Accent = Color3.fromRGB(0, 229, 255),
})

-- Watch CoreGui for the text and immediately change it
local function checkAndReplace(obj)
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        task.spawn(function()
            repeat
                if obj.Text and (obj.Text:find("%$hane") or obj.Text:find("Haze") or obj.Text:find("HAZE") or obj.Text:find("Holographic") or obj.Text:find("holographic")) then
                    obj.Text = "https://discord.gg/8fjVDektPK"
                end
                task.wait(0.05)
            until not obj or not obj.Parent
        end)
    elseif obj:IsA("ImageLabel") then
        if obj.Name == "Logo" or obj.Name == "Icon" then
            obj.Visible = false
        end
    end
end

for _, v in ipairs(CoreGui:GetDescendants()) do checkAndReplace(v) end
CoreGui.DescendantAdded:Connect(checkAndReplace)

local MainTab = Window:CreateTab({ Name = "Main", Icon = "◆" })
local VisualsTab = Window:CreateTab({ Name = "Visuals", Icon = "👁" })
local TrollingTab = Window:CreateTab({ Name = "Trolling", Icon = "🎭" })

local FlightSection = MainTab:CreateSection("Flight")
FlightSection:CreateToggle({ Name = "Enable Fly", Default = false, Callback = function(v) if v then startFly() else stopFly() end end })
FlightSection:CreateSlider({ Name = "Fly Speed", Min = 20, Max = 500, Default = 60, Step = 10, Callback = function(v) State.flySpeed = v end })
FlightSection:CreateSlider({ Name = "Fly Vert", Min = 0.5, Max = 5, Default = 1.5, Step = 0.5, Callback = function(v) State.flyVert = v end })
FlightSection:CreateSlider({ Name = "Fly Smooth", Min = 1, Max = 30, Default = 8, Step = 1, Callback = function(v) State.flySmooth = v end })

local CombatSection = MainTab:CreateSection("Combat")
CombatSection:CreateToggle({ Name = "Aimbot", Default = false, Callback = function(v) if v then startAimbot() else stopAimbot() end end })
CombatSection:CreateDropdown({ Name = "Aim Part", Options = {"Head", "UpperTorso", "HumanoidRootPart"}, Multi = false, Callback = function(v) State.aimPart = v end })
CombatSection:CreateSlider({ Name = "FOV", Min = 50, Max = 500, Default = 150, Step = 10, Callback = function(v) State.aimFov = v end })
CombatSection:CreateSlider({ Name = "Smoothness", Min = 1, Max = 100, Default = 15, Step = 1, Callback = function(v) State.aimSmooth = v / 100 end })

local HitboxSection = MainTab:CreateSection("Hitbox")
HitboxSection:CreateToggle({ Name = "Expand Hitbox", Default = false, Callback = function(v) if v then enableHitbox() else disableHitbox() end end })
HitboxSection:CreateSlider({ Name = "Size", Min = 3, Max = 30, Default = 10, Step = 1, Callback = function(v) State.hitboxSize = v; if State.hitbox then disableHitbox(); enableHitbox() end end })

local MoveSection = MainTab:CreateSection("Movement")
MoveSection:CreateToggle({ Name = "Noclip", Default = false, Callback = function(v) setNoclip(v) end })
MoveSection:CreateToggle({ Name = "Infinite Jump", Default = false, Callback = function(v) State.infJump = v end })
MoveSection:CreateButton({ Name = "Teleport to Mouse", Callback = function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild('HumanoidRootPart')
    if hrp then hrp.CFrame = CFrame.new(LocalPlayer:GetMouse().Hit.Position + Vector3.new(0, 3, 0)) end
end })

local SpinSection = MainTab:CreateSection("Spinbot")
SpinSection:CreateToggle({ Name = "Enable Spinbot", Default = false, Callback = function(v) if v then startSpin() else stopSpin() end end })
SpinSection:CreateSlider({ Name = "Speed", Min = 10, Max = 200, Default = 50, Step = 10, Callback = function(v) State.spinSpeed = v end })

local EspSection = VisualsTab:CreateSection("ESP")
EspSection:CreateToggle({ Name = "ESP (Green Box)", Default = false, Callback = function(v) if v then startESP() else stopESP() end end })

local TracerSection = VisualsTab:CreateSection("Tracers")
TracerSection:CreateToggle({ Name = "Tracers", Default = false, Callback = function(v) if v then startTracers() else stopTracers() end end })

local SpamSection = TrollingTab:CreateSection("Chat Spammer")
SpamSection:CreateToggle({ Name = "Enable Chat Spam", Default = false, Callback = function(v) if v then startChatSpam() else stopChatSpam() end end })
SpamSection:CreateTextbox({ Name = "Message", Default = "EuroWare on top!", Placeholder = "Type message...", Callback = function(text) State.chatSpamMessage = text end })
SpamSection:CreateSlider({ Name = "Delay (s)", Min = 0.5, Max = 10, Default = 1.5, Step = 0.5, Callback = function(v) State.chatSpamDelay = v end })

local ConsoleSection = TrollingTab:CreateSection("Console")
local ConsoleTextbox = ConsoleSection:CreateTextbox({ Name = "Console Text", Default = "Hello World", Placeholder = "Type to print...", Callback = function(text) end })
ConsoleSection:CreateButton({ Name = "Print to Console", Callback = function()
    print("[EuroWare Custom Print] " .. ConsoleTextbox:Get())
end })

LocalPlayer.Chatted:Connect(function(msg)
    if msg:lower() == "!stop" and State.chatSpamEnabled then
        State.chatSpamEnabled = false
        if State.chatSpamThread then task.cancel(State.chatSpamThread); State.chatSpamThread = nil end
        Haze:Notify({ Title = "EuroWare", Text = "Chat spam stopped by !stop command", Duration = 3 })
    end
end)

UserInputService.JumpRequest:Connect(function()
    if State.infJump then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if State.flying then stopFly() end
    if State.spin then stopSpin() end
end)

Haze:Notify({
    Title = "EuroWare Loaded",
    Text = "Press K to toggle the menu. Join discord.gg/8fjVDektPK",
    Duration = 5
})
