local Drawing = Drawing

-- Vape UI Library laden
local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/UI-Libs/main/Vape.txt"))()

-- Fenster erstellen
local win = lib:Window("W1lteGameYT Hub", Color3.fromRGB(44, 120, 224), Enum.KeyCode.RightAlt)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ===================== EINSTELLUNGEN =====================
local Settings = {
    Aimbot = {
        Enabled = true,
        TeamCheck = "FFA",
        FOV = 500,
        ShowFOVCircle = true,
        Smoothing = 4,
        ActivationDelay = 0,
        ActivationKey = Enum.UserInputType.MouseButton2
    },
    ESP = {
        Enabled = true,
        Color = Color3.fromRGB(0, 255, 127)
    },
    AntiSpectate = false
}

local State = {
    Aimbot = {
        IsKeyDown = false,
        KeyDownTimestamp = 0
    },
    FOVCircle = Drawing.new("Circle"),
    OriginalTransparencies = {},
    UIVisible = true  -- UI Sichtbarkeit
}

-- ===================== HILFSFUNKTIONEN =====================
local function IsEnemy(player)
    if not player or player == LocalPlayer then return false end
    local check = Settings.Aimbot.TeamCheck
    if check == "FFA" or check == "Everyone" then return true end
    if check == "Team-Based" and player.Team ~= LocalPlayer.Team then return true end
    return false
end

local function GetBestTarget()
    local bestTarget = nil
    local smallestMagnitude = Settings.Aimbot.FOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if IsEnemy(player) and character and humanoid and humanoid.Health > 0 then
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

-- ===================== ANTI-SPECTATE =====================
local function RestoreAppearance()
    for part, transparency in pairs(State.OriginalTransparencies) do
        if part and part.Parent then
            pcall(function()
                part.LocalTransparencyModifier = transparency
            end)
        end
    end
    State.OriginalTransparencies = {}
end

local function ApplyInvisibility()
    local character = LocalPlayer.Character
    if not character then return end

    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") or descendant:IsA("Decal") then
            if not State.OriginalTransparencies[descendant] then
                State.OriginalTransparencies[descendant] = descendant.LocalTransparencyModifier
            end
            descendant.LocalTransparencyModifier = 1
        end
    end
end

-- ===================== ESP FUNKTIONEN =====================
local function RemoveESPVisuals(character)
    if not character then return end
    local highlight = character:FindFirstChild("Nexus_HL")
    if highlight then highlight:Destroy() end
    local head = character:FindFirstChild("Head")
    if head then
        local tag = head:FindFirstChild("Nexus_Tag")
        if tag then tag:Destroy() end
    end
end

local function ApplyESP(player)
    local character = player.Character
    if not character then return end
    if not Settings.ESP.Enabled or not IsEnemy(player) then
        RemoveESPVisuals(character)
        return
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local head = character:FindFirstChild("Head")
    if not humanoid or humanoid.Health <= 0 then
        RemoveESPVisuals(character)
        return
    end

    -- Highlight
    local highlight = character:FindFirstChild("Nexus_HL")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "Nexus_HL"
        highlight.Parent = character
    end
    highlight.FillColor = Settings.ESP.Color
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

-- ===================== UI ERSTELLEN =====================
-- Haupt-Tab
local mainTab = win:Tab("Main")

-- Aimbot Section
mainTab:Label("> AIMBOT")
mainTab:Toggle("Aimbot aktivieren", Settings.Aimbot.Enabled, function(val)
    Settings.Aimbot.Enabled = val
end)
mainTab:Slider("FOV Radius", 10, 500, Settings.Aimbot.FOV, false, function(val)
    Settings.Aimbot.FOV = val
end)
mainTab:Slider("Smoothing", 1, 50, Settings.Aimbot.Smoothing, false, function(val)
    Settings.Aimbot.Smoothing = val
end)
mainTab:Dropdown("Team Check", {"FFA", "Team-Based", "Everyone"}, function(val)
    Settings.Aimbot.TeamCheck = val
end)
mainTab:Toggle("FOV Kreis anzeigen", Settings.Aimbot.ShowFOVCircle, function(val)
    Settings.Aimbot.ShowFOVCircle = val
end)
mainTab:Label("Aktiviere mit rechter Maustaste")

-- ESP Section
mainTab:Label("> ESP")
mainTab:Toggle("ESP aktivieren", Settings.ESP.Enabled, function(val)
    Settings.ESP.Enabled = val
    if not val then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then RemoveESPVisuals(player.Character) end
        end
    end
end)
mainTab:ColorPicker("ESP Farbe", Settings.ESP.Color, function(val)
    Settings.ESP.Color = val
end)

-- Anti-Spectate
mainTab:Label("> PRIVATSPHÄRE")
mainTab:Toggle("Anti-Spectate", Settings.AntiSpectate, function(val)
    Settings.AntiSpectate = val
    if not val then
        RestoreAppearance()
    end
end)

-- ===================== FOV KREIS SETUP =====================
local circle = State.FOVCircle
circle.Visible = false
circle.Thickness = 1
circle.Color = Color3.fromRGB(255, 255, 255)
circle.Filled = false
circle.NumSides = 64
circle.Transparency = 1
circle.Radius = Settings.Aimbot.FOV

-- ===================== INPUT HANDLING =====================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    -- Aimbot Aktivierung
    if input.UserInputType == Settings.Aimbot.ActivationKey then
        State.Aimbot.IsKeyDown = true
        State.Aimbot.KeyDownTimestamp = tick()
    end

    -- UI mit + Taste umschalten (NUR Sichtbarkeit, Funktionen bleiben an)
    if input.KeyCode == Enum.KeyCode.Plus or input.KeyCode == Enum.KeyCode.Equals then
        State.UIVisible = not State.UIVisible
        -- UI unsichtbar machen aber Funktionen bleiben aktiv
        local gui = lib:GetGUI()
        if gui then
            gui.Enabled = State.UIVisible
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Settings.Aimbot.ActivationKey then
        State.Aimbot.IsKeyDown = false
    end
end)

-- Charakter-Entfernung aufräumen
LocalPlayer.CharacterRemoving:Connect(function()
    RestoreAppearance()
end)

-- Spieler verlässt Spiel
Players.PlayerRemoving:Connect(function(player)
    if player.Character then RemoveESPVisuals(player.Character) end
end)

-- ===================== RENDER LOOP =====================
RunService:BindToRenderStep("MainRender", Enum.RenderPriority.Camera.Value + 1, function()
    -- Anti-Spectate (funktioniert auch bei unsichtbarer UI)
    if Settings.AntiSpectate then
        ApplyInvisibility()
    elseif next(State.OriginalTransparencies) ~= nil then
        RestoreAppearance()
    end

    -- ESP Update (funktioniert auch bei unsichtbarer UI)
    for _, player in ipairs(Players:GetPlayers()) do
        ApplyESP(player)
    end

    -- Aimbot (funktioniert auch bei unsichtbarer UI)
    local aimbot = Settings.Aimbot
    local aimbotState = State.Aimbot

    -- FOV Kreis aktualisieren (funktioniert auch bei unsichtbarer UI)
    circle.Visible = aimbot.Enabled and aimbot.ShowFOVCircle and aimbotState.IsKeyDown
    if circle.Visible then
        circle.Position = UserInputService:GetMouseLocation()
        circle.Radius = aimbot.FOV
    end

    -- Zielverfolgung (funktioniert auch bei unsichtbarer UI)
    if aimbot.Enabled and aimbotState.IsKeyDown then
        local target = GetBestTarget()
        if target then
            local targetScreenPos, onScreen = Camera:WorldToScreenPoint(target.AimPosition)
            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                local moveVector = Vector2.new(
                    targetScreenPos.X - mousePos.X,
                    targetScreenPos.Y - mousePos.Y
                )
                if mousemoverel then
                    mousemoverel(
                        moveVector.X / aimbot.Smoothing,
                        moveVector.Y / aimbot.Smoothing
                    )
                end
            end
        end
    end
end)
