--[[
    CAMERA LOCK-ON SYSTEM (MOBILE) - ROBLOX LUAU
    - Tương thích Executor Delta
    - Hoạt động mượt ở cả First & Third Person
    - Tự động hủy theo dõi nếu mục tiêu vượt ra ngoài FOV
--]]

-- Đợi game tải hoàn toàn
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Đợi PlayerGui sẵn sàng
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local AimbotEnabled = true
local FOV_RADIUS = 100  -- Tăng từ 35 lên 45 (hoặc 50 nếu muốn)
local TARGET_PART = "Head"

-- ================== VÒNG TRÒN FOV ==================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(0, 255, 0)     -- Xanh lá
FOVCircle.Filled = false
FOVCircle.Radius = FOV_RADIUS
FOVCircle.Visible = true

-- ================== HÀM TÌM MỤC TIÊU ==================
local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(TARGET_PART) and player.Character:FindFirstChildOfClass("Humanoid") then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid.Health > 0 then
                local targetPart = player.Character[TARGET_PART]

                -- Kiểm tra tia quét vật cản (Line-of-Sight)
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, player.Character}

                local origin = Camera.CFrame.Position
                local direction = targetPart.Position - origin
                local raycastResult = workspace:Raycast(origin, direction, raycastParams)

                -- Chỉ nhận mục tiêu khi không bị che khuất và nằm trong FOV
                if not raycastResult then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local targetPos2D = Vector2.new(screenPos.X, screenPos.Y)
                        local distanceToCenter = (targetPos2D - screenCenter).Magnitude

                        if distanceToCenter <= FOV_RADIUS and distanceToCenter < shortestDistance then
                            closestPlayer = player
                            shortestDistance = distanceToCenter
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- ================== CẬP NHẬT CAMERA LOCK ==================
local function updateCameraLock()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Position = screenCenter

    if not AimbotEnabled then
        FOVCircle.Visible = false
        return
    end

    FOVCircle.Visible = true

    local targetPlayer = getClosestPlayer()
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild(TARGET_PART) then
        local targetPos = targetPlayer.Character[TARGET_PART].Position
        
        -- ÉP BUỘC CAMERA NHÌN THẲNG VÀO ĐẦU MỤC TIÊU
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
    end
end

-- ================== QUẢN LÝ VÒNG LẶP ==================
local function startAimbot()
    RunService:BindToRenderStep("CameraLock", Enum.RenderPriority.Camera.Value + 1, updateCameraLock)
end

local function stopAimbot()
    RunService:UnbindFromRenderStep("CameraLock")
    FOVCircle.Visible = false
end

-- Bật mặc định
startAimbot()

-- ================== TẠO GUI TOGGLE (KÉO/THẢ CẢM ỨNG) ==================
if PlayerGui:FindFirstChild("MobileAimbotGui") then
    PlayerGui.MobileAimbotGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "MobileAimbotGui"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
ToggleButton.Position = UDim2.new(0.15, 0, 0.25, 0)
ToggleButton.Size = UDim2.new(0, 75, 0, 35)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "TRACK: ON"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14.0
ToggleButton.Active = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

-- Cơ chế kéo/thả mượt bằng cảm ứng
local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
    local delta = input.Position - dragStart
    ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = ToggleButton.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

ToggleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

-- ================== XỬ LÝ BẬT/TẮT HỆ THỐNG ==================
ToggleButton.MouseButton1Click:Connect(function()
    AimbotEnabled = not AimbotEnabled
    if AimbotEnabled then
        ToggleButton.Text = "TRACK: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        FOVCircle.Visible = true
        startAimbot()
    else
        ToggleButton.Text = "TRACK: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        stopAimbot()
    end
end)
