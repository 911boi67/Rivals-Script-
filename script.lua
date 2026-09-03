local Drawing = Drawing

local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/UI-Libs/main/Vape.txt"))() 
local win = lib:Window("W1lteGameYT Hub", Color3.fromRGB(44, 120, 224), Enum.KeyCode.P) 
 
local Players = game:GetService("Players") 
local RunService = game:GetService("RunService") 
local UserInputService = game:GetService("UserInputService") 
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer 
local Camera = workspace.CurrentCamera 

-- ===================== ADVANCE TECH (AIMBOT) =====================
local AdvanceTech = {} 

AdvanceTech.Settings = { 
    Aimbot = { 
        Enabled = true, 
        TeamCheck = "FFA", 
        FOV = 120, 
        ShowFOVCircle = true, 
        Smoothing = 10, 
        ActivationDelay = 0.07, 
        ActivationKey = Enum.UserInputType.MouseButton2 
    }, 
    Privacy = { 
        AntiSpectate = true 
    } 
} 

AdvanceTech.State = { 
    Aimbot = { 
        IsKeyDown = false, 
        KeyDownTimestamp = 0 
    }, 
    Privacy = { 
        OriginalTransparencies = {} 
    }, 
    UI = { 
        IsVisible = true, 
        FOVCircle = Drawing.new("Circle") 
    } 
} 

function AdvanceTech:IsEnemy(player) 
    if not player or player == LocalPlayer then return false end 
    local check = self.Settings.Aimbot.TeamCheck 
    if check == "FFA" or check == "Everyone" then return true end 
    if check == "Team-Based" and player.Team ~= LocalPlayer.Team then return true end 
    return false 
end 

function AdvanceTech:GetBestTarget() 
    local bestTarget = nil 
    local smallestMagnitude = self.Settings.Aimbot.FOV 
    local mousePos = UserInputService:GetMouseLocation() 

    for _, player in ipairs(Players:GetPlayers()) do 
        local character = player.Character 
        local humanoid = character and character:FindFirstChildOfClass("Humanoid") 
         
        if self:IsEnemy(player) and character and humanoid and humanoid.Health > 0 then 
            local targetPart = character:FindFirstChild("HumanoidRootPart") 
             
            if targetPart then 
                local aimPosition = targetPart.Position 
                local screenPos, onScreen = Camera:WorldToScreenPoint(aimPosition) 

                if onScreen then 
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude 
                    if distance < smallestMagnitude then 
                        smallestMagnitude = distance 
                        bestTarget = { AimPosition = aimPosition } 
                    end 
                end 
            end 
        end 
    end 
    return bestTarget 
end 

function AdvanceTech:RestoreAppearance() 
    for part, transparency in pairs(self.State.Privacy.OriginalTransparencies) do 
        if part and part.Parent then 
            part.LocalTransparencyModifier = transparency 
        end 
    end 
    self.State.Privacy.OriginalTransparencies = {} 
end 

function AdvanceTech:ApplyInvisibility() 
    local character = LocalPlayer.Character 
    if not character then return end 

    for _, descendant in ipairs(character:GetDescendants()) do 
        if descendant:IsA("BasePart") or descendant:IsA("Decal") then 
            if not self.State.Privacy.OriginalTransparencies[descendant] then 
                self.State.Privacy.OriginalTransparencies[descendant] = descendant.LocalTransparencyModifier 
            end 
            descendant.LocalTransparencyModifier = 1 
        end 
    end 
end 

-- ===================== ESP SYSTEM =====================
local ESP = {
    Enabled = false,
    Color = Color3.fromRGB(0, 255, 127),
    BG = Color3.fromRGB(15, 15, 15),
    MenuVisible = true
}

function ESP:IsEnemy(player)
    if not player or player == LocalPlayer then return false end
    if player.Team ~= nil and player.Team == LocalPlayer.Team then return false end
    return true
end

function ESP:RemoveVisuals(character)
    if not character then return end
    local highlight = character:FindFirstChild("Nexus_HL")
    if highlight then highlight:Destroy() end
    local head = character:FindFirstChild("Head")
    if head then
        local tag = head:FindFirstChild("Nexus_Tag")
        if tag then tag:Destroy() end
    end
end

function ESP:ApplyVisuals(player)
    local character = player.Character
    if not character then return end
    if not self.Enabled or not self:IsEnemy(player) then
        self:RemoveVisuals(character)
        return
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local head = character:FindFirstChild("Head")
    if not humanoid or humanoid.Health <= 0 then
        self:RemoveVisuals(character)
        return
    end
    
    -- Highlight
    local highlight = character:FindFirstChild("Nexus_HL")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "Nexus_HL"
        highlight.Parent = character
    end
    highlight.FillColor = self.Color
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    -- Name + HP Tag
    if head then
        local tag = head:FindFirstChild("Nexus_Tag")
        if not tag then
            tag = Instance.new("BillboardGui")
            tag.Name = "Nexus_Tag"
            tag.Size = UDim2.new(0, 120, 0, 40)
            tag.StudsOffset = Vector3.new(0, 2.5, 0)
            tag.AlwaysOnTop = true
            tag.Parent = head
            local label = Instance.new("TextLabel")
            label.Name = "Info"
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextStrokeTransparency = 0.4
            label.Font = Enum.Font.GothamBold
            label.TextSize = 12
            label.Parent = tag
        end
        tag.Info.Text = player.Name .. "\nHP: " .. math.floor(humanoid.Health)
    end
end

function ESP:BuildUI()
    if CoreGui:FindFirstChild("Nexus_ESP") then
        CoreGui.Nexus_ESP:Destroy()
    end
    local gui = Instance.new("ScreenGui")
    gui.Name = "Nexus_ESP"
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui
    
    local menu = Instance.new("Frame")
    menu.Size = UDim2.new(0, 230, 0, 140)
    menu.Position = UDim2.new(0.5, -115, 0.2, 0)
    menu.BackgroundColor3 = ESP.BG
    menu.Parent = gui
    Instance.new("UICorner", menu)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = "PLAYER ESP"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.BackgroundTransparency = 1
    title.Parent = menu
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.85, 0, 0, 40)
    button.Position = UDim2.new(0.075, 0, 0.4, 0)
    button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    button.Text = "ESP: OFF"
    button.TextColor3 = Color3.fromRGB(160, 160, 160)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.Parent = menu
    Instance.new("UICorner", button)
    
    button.MouseButton1Click:Connect(function()
        ESP.Enabled = not ESP.Enabled
        button.Text = ESP.Enabled and "ESP: ON" or "ESP: OFF"
        button.TextColor3 = ESP.Enabled and ESP.Color or Color3.fromRGB(160, 160, 160)
        if not ESP.Enabled then
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character then ESP:RemoveVisuals(player.Character) end
            end
        end
    end)
    
    -- Drag menu
    local dragging = false
    local dragStart, startPosition
    menu.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPosition = menu.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            menu.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- ===================== UI MAIN TAB (Aimbot Settings) =====================
local mainTab = win:Tab("Main") 
mainTab:Label("> Aimbot / Target Lock") 
mainTab:Toggle("Enable Aimbot", AdvanceTech.Settings.Aimbot.Enabled, function(val) AdvanceTech.Settings.Aimbot.Enabled = val end) 
mainTab:Slider("FOV Radius", 10, 500, AdvanceTech.Settings.Aimbot.FOV, function(val) AdvanceTech.Settings.Aimbot.FOV = val end) 
mainTab:Slider("Aim Smoothing", 1, 50, AdvanceTech.Settings.Aimbot.Smoothing, function(val) AdvanceTech.Settings.Aimbot.Smoothing = val end) 
mainTab:Slider("Activation Delay", 0, 50, AdvanceTech.Settings.Aimbot.ActivationDelay * 100, function(val) AdvanceTech.Settings.Aimbot.ActivationDelay = val / 100 end) 
mainTab:Dropdown("Team Check", {"FFA", "Team-Based", "Everyone"}, function(val) AdvanceTech.Settings.Aimbot.TeamCheck = val end) 
mainTab:Toggle("Show FOV Circle", AdvanceTech.Settings.Aimbot.ShowFOVCircle, function(val) AdvanceTech.Settings.Aimbot.ShowFOVCircle = val end) 
mainTab:Label("Hold Right-Click to Activate Aimbot.") 
mainTab:Label("Targeting is locked to Body.") 

-- ===================== FOV Circle Setup =====================
local circle = AdvanceTech.State.UI.FOVCircle 
circle.Visible = false 
circle.Thickness = 1 
circle.Color = Color3.fromRGB(255, 255, 255) 
circle.Filled = false 
circle.NumSides = 64 

-- ===================== Input Handling =====================
UserInputService.InputBegan:Connect(function(input, gpe) 
    if gpe then return end 
    -- Toggle main UI
    if input.KeyCode == Enum.KeyCode.RightAlt then 
        AdvanceTech.State.UI.IsVisible = not AdvanceTech.State.UI.IsVisible 
        win:Toggle(AdvanceTech.State.UI.IsVisible)
    end 
    -- Toggle ESP menu with 0
    if input.KeyCode == Enum.KeyCode.Zero then 
        ESP.MenuVisible = not ESP.MenuVisible
        local gui = CoreGui:FindFirstChild("Nexus_ESP")
        if gui then gui.Enabled = ESP.MenuVisible end
    end
    -- Aimbot activation
    if input.UserInputType == AdvanceTech.Settings.Aimbot.ActivationKey then 
        AdvanceTech.State.Aimbot.IsKeyDown = true 
        AdvanceTech.State.Aimbot.KeyDownTimestamp = tick() 
    end 
end) 

UserInputService.InputEnded:Connect(function(input) 
    if input.UserInputType == AdvanceTech.Settings.Aimbot.ActivationKey then 
        AdvanceTech.State.Aimbot.IsKeyDown = false 
    end 
end) 

-- ===================== Cleanup on Character Removal =====================
LocalPlayer.CharacterRemoving:Connect(function() 
    AdvanceTech:RestoreAppearance() 
end) 

-- ===================== Player Leave Cleanup (ESP) =====================
Players.PlayerRemoving:Connect(function(player) 
    if player.Character then ESP:RemoveVisuals(player.Character) end 
end) 

-- ===================== Render Loop (Combined) =====================
RunService:BindToRenderStep("AdvanceTechRender", Enum.RenderPriority.Camera.Value + 1, function() 
    -- Anti-Spectate
    if AdvanceTech.Settings.Privacy.AntiSpectate then 
        AdvanceTech:ApplyInvisibility() 
    end 

    -- ESP Update
    for _, player in ipairs(Players:GetPlayers()) do 
        ESP:ApplyVisuals(player) 
    end 

    -- Aim assist
    local aimbot = AdvanceTech.Settings.Aimbot 
    local aimbotState = AdvanceTech.State.Aimbot 

    circle.Visible = aimbot.Enabled and aimbot.ShowFOVCircle and aimbotState.IsKeyDown 
    if circle.Visible then 
        circle.Position = UserInputService:GetMouseLocation() 
        circle.Radius = aimbot.FOV 
    end 

    if aimbot.Enabled and aimbotState.IsKeyDown and (tick() - aimbotState.KeyDownTimestamp > aimbot.ActivationDelay) then 
        local target = AdvanceTech:GetBestTarget() 
        if target then 
            local targetScreenPos, onScreen = Camera:WorldToScreenPoint(target.AimPosition) 
            if onScreen then 
                local mousePos = UserInputService:GetMouseLocation() 
                local moveVector = Vector2.new(targetScreenPos.X - mousePos.X, targetScreenPos.Y - mousePos.Y) 
                if mousemoverel then 
                    mousemoverel(moveVector.X / aimbot.Smoothing, moveVector.Y / aimbot.Smoothing) 
                end 
            end 
        end 
    end 
end)

-- ===================== Build ESP UI =====================
ESP:BuildUI()
