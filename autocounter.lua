-- Mind Reader Auto-Counter v3 Ultra-Final
-- Works with Delta executor (mobile)
-- Perfect timing + GUI + logs + safe reconnects

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- Remotes
local remotes = ReplicatedStorage:WaitForChild("remotes")
local re = remotes:WaitForChild("re")
local counterRemote = re:WaitForChild("Block")
print("[INFO] Counter remote found:", counterRemote.Name)

-- Settings
local COUNTER_DELAY = 0.05
local DETECT_RANGE = 20
local AUTO_PARRY = true
local SLAP_ANIM_ID = "rbxassetid://507766388"
local lastCounter = 0
local DEBOUNCE_TIME = 0.5

-- Logging
local function log(msg)
    print("[AutoCounter]["..os.date("%X").."] "..msg)
end

-- Slap detection
local function isSlapping(player)
    local oppChar = player.Character
    if not oppChar or not oppChar:FindFirstChild("Humanoid") then return false end

    local humanoid = oppChar.Humanoid
    local animator = humanoid:FindFirstChild("Animator")
    if animator then
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            if track.Animation.AnimationId == SLAP_ANIM_ID or track.Name:lower():find("slap") then
                return true
            end
        end
    end

    local tool = oppChar:FindFirstChildOfClass("Tool")
    if tool and tool.Name:lower():find("slap") then
        return true
    end

    return false
end

-- Counter fire
local function doCounter()
    local now = tick()
    if now - lastCounter < DEBOUNCE_TIME then return end
    lastCounter = now
    counterRemote:FireServer()
    log("Counter fired!")
end

-- Update loop
local function update()
    if not AUTO_PARRY then return end
    local myRoot = Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local oppRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if not oppRoot then continue end
            local distance = (oppRoot.Position - myRoot.Position).Magnitude
            if distance <= DETECT_RANGE and isSlapping(player) then
                spawn(function()
                    wait(COUNTER_DELAY)
                    doCounter()
                end)
                break
            end
        end
    end
end

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoCounterGUI"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleBtn"
toggleBtn.Size = UDim2.new(0, 200, 0, 60)
toggleBtn.Position = UDim2.new(1, -220, 0, 20)
toggleBtn.BackgroundColor3 = Color3.new(0,1,0)
toggleBtn.Text = "Auto Counter: ON"
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = screenGui

local function updateBtn()
    if AUTO_PARRY then
        toggleBtn.BackgroundColor3 = Color3.new(0,1,0)
        toggleBtn.Text = "Auto Counter: ON"
    else
        toggleBtn.BackgroundColor3 = Color3.new(1,0,0)
        toggleBtn.Text = "Auto Counter: OFF"
    end
end

toggleBtn.MouseButton1Click:Connect(function()
    AUTO_PARRY = not AUTO_PARRY
    updateBtn()
    log("Auto-counter toggled: "..(AUTO_PARRY and "ON" or "OFF"))
end)

-- Draggable
local dragging = false
local dragStart, startPos
toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = toggleBtn.Position
    end
end)
toggleBtn.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
toggleBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

updateBtn()

RunService.Heartbeat:Connect(update)

-- Reconnect on respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    log("Character respawned, references updated")
end)

log("Mind Reader Auto-Counter v3 Ultra-Final loaded! Drag/tap button to toggle.")
