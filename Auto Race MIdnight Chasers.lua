
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local autoRaceActive = false
local targetSpeed = 500 -- Tốc độ tự lái mặc định
local carStabilizationConnection = nil

-- Tạo GUI chính
local guiScreen = Instance.new("ScreenGui")
guiScreen.Name = "KeitazRaceGUI"
guiScreen.ResetOnSpawn = false
guiScreen.IgnoreGuiInset = true
guiScreen.Parent = player.PlayerGui

local guiFrame = Instance.new("Frame")
guiFrame.Size = UDim2.new(0, 300, 0, 190)
guiFrame.Position = UDim2.new(0.5, -150, 0.5, -95)
guiFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
guiFrame.BorderSizePixel = 0
guiFrame.Parent = guiScreen
Instance.new("UICorner", guiFrame).CornerRadius = UDim.new(0, 14)

local frameStroke = Instance.new("UIStroke", guiFrame)
frameStroke.Color = Color3.fromRGB(44, 44, 50)
frameStroke.Thickness = 1.5

-- Tiêu đề GUI
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -24, 0, 30)
titleLabel.Position = UDim2.new(0, 12, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Keitaz Auto Physical Race"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 17
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = guiFrame

local div1 = Instance.new("Frame")
div1.Size = UDim2.new(1, -24, 0, 1)
div1.Position = UDim2.new(0, 12, 0, 45)
div1.BackgroundColor3 = Color3.fromRGB(36, 36, 42)
div1.BorderSizePixel = 0
div1.Parent = guiFrame

-- Nút ON/OFF Auto Race
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -24, 0, 40)
toggleBtn.Position = UDim2.new(0, 12, 0, 55)
toggleBtn.Text = "Auto Race: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 46)
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = guiFrame
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

local toggleStroke = Instance.new("UIStroke", toggleBtn)
toggleStroke.Color = Color3.fromRGB(220, 55, 55)
toggleStroke.Thickness = 1.5

-- Nhãn "Race Speed"
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0, 120, 0, 35)
speedLabel.Position = UDim2.new(0, 12, 0, 110)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Race Speed:"
speedLabel.TextColor3 = Color3.fromRGB(175, 175, 175)
speedLabel.TextSize = 14
speedLabel.Font = Enum.Font.GothamMedium
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = guiFrame

-- Ô nhập tốc độ di chuyển (TextBox)
local speedInput = Instance.new("TextBox")
speedInput.Size = UDim2.new(1, -150, 0, 35)
speedInput.Position = UDim2.new(0, 138, 0, 110)
speedInput.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
speedInput.BorderSizePixel = 0
speedInput.Text = tostring(targetSpeed)
speedInput.PlaceholderText = "Tốc độ (e.g. 500)..."
speedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
speedInput.TextSize = 14
speedInput.Font = Enum.Font.GothamBold
speedInput.Parent = guiFrame
Instance.new("UICorner", speedInput).CornerRadius = UDim.new(0, 8)

local inputStroke = Instance.new("UIStroke", speedInput)
inputStroke.Color = Color3.fromRGB(44, 44, 50)
inputStroke.Thickness = 1

-- Trạng thái Status dưới cùng
local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -24, 0, 20)
statusText.Position = UDim2.new(0, 12, 0, 155)
statusText.BackgroundTransparency = 1
statusText.Text = "Status: Ready (Start a race first)"
statusText.TextColor3 = Color3.fromRGB(135, 135, 135)
statusText.TextSize = 11
statusText.Font = Enum.Font.GothamMedium
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = guiFrame

-- Các hàm hỗ trợ kiểm tra trạng thái xe
local function isPlayerSeated()
    local char = player.Character
    if char then 
        local hum = char:FindFirstChild("Humanoid")
        if hum and hum.SeatPart then return true end 
    end
    return false
end

local function getCar()
    local char = player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum and hum.SeatPart then
            return hum.SeatPart:FindFirstAncestorWhichIsA("Model")
        end
    end
    return nil
end

-- Tự động quét tìm checkpoint trong Workspace
local function getRaceCheckpoints()
    local checkpoints = {}
    
    -- 1. Chỉ định các thư mục chứa cuộc đua phổ biến của game để quét trực tiếp (tránh gây lag)
    local targetFolders = {
        workspace:FindFirstChild("Races"),
        workspace:FindFirstChild("CurrentRace"),
        workspace:FindFirstChild("ActiveRace"),
        workspace:FindFirstChild("RaceGates"),
        workspace:FindFirstChild("Map")
    }
    
    -- Quét nhanh trong các thư mục mục tiêu trước
    for _, folder in pairs(targetFolders) do
        if folder then
            for _, child in pairs(folder:GetDescendants()) do
                local nameLower = string.lower(child.Name)
                if child:IsA("BasePart") and (
                    string.find(nameLower, "gate") or 
                    string.find(nameLower, "checkpoint") or 
                    string.find(nameLower, "cp") or 
                    string.find(nameLower, "ring") or
                    string.find(nameLower, "waypoint")
                ) then
                    table.insert(checkpoints, child)
                end
            end
        end
    end
    
    -- 2. Phương án dự phòng: Nếu không thấy, chỉ quét các thư mục cấp 1 ngoài Workspace có tên liên quan đến Race/Gate
    if #checkpoints == 0 then
        for _, child in pairs(workspace:GetChildren()) do
            if child:IsA("Folder") or child:IsA("Model") then
                local nameLower = string.lower(child.Name)
                if string.find(nameLower, "race") or string.find(nameLower, "checkpoint") or string.find(nameLower, "gate") then
                    for _, subChild in pairs(child:GetDescendants()) do
                        if subChild:IsA("BasePart") then
                            table.insert(checkpoints, subChild)
                        end
                    end
                end
            end
        end
    end
    
    -- Sắp xếp các checkpoint theo thứ tự số tăng dần xuất hiện trong tên (ví dụ: Gate1, Gate2, CP1...)
    if #checkpoints > 0 then
        table.sort(checkpoints, function(a, b)
            local numA = tonumber(string.match(a.Name, "%d+")) or 0
            local numB = tonumber(string.match(b.Name, "%d+")) or 0
            return numA < numB
        end)
    end
    
    return checkpoints
end

-- Hàm giữ thăng bằng cho xe tránh lật
local function stabilizeCar(car)
    if carStabilizationConnection then carStabilizationConnection:Disconnect() end
    carStabilizationConnection = RunService.Heartbeat:Connect(function()
        if not autoRaceActive or not car.Parent or not car.PrimaryPart then
            if carStabilizationConnection then 
                carStabilizationConnection:Disconnect(); carStabilizationConnection = nil 
            end
            return
        end
        local cf = car.PrimaryPart.CFrame; local pos, look = cf.Position, cf.LookVector
        car.PrimaryPart.CFrame = car.PrimaryPart.CFrame:Lerp(CFrame.new(pos, pos + Vector3.new(look.X, 0, look.Z)), 0.15)
        car.PrimaryPart.AssemblyAngularVelocity = Vector3.new(0, car.PrimaryPart.AssemblyAngularVelocity.Y * 0.5, 0)
    end)
end

-- Hàm tự lái di chuyển vật lý mượt mà qua các tọa độ
local function smoothNavigateToCar(car, targetPos, maxSpeed)
    local curSpeed = maxSpeed * 0.4
    while autoRaceActive and isPlayerSeated() do
        if not car.Parent or not car.PrimaryPart then break end
        local currentPos = car.PrimaryPart.Position
        local distance = (targetPos - currentPos).Magnitude
        
        -- Khoảng cách tiếp cận checkpoint (30 là tối ưu để chạm vòng va chạm của game)
        if distance < 30 then break end
        
        curSpeed = math.min(curSpeed + (maxSpeed * 0.02), maxSpeed)
        local direction = (targetPos - currentPos).Unit
        car.PrimaryPart.AssemblyLinearVelocity = car.PrimaryPart.AssemblyLinearVelocity:Lerp(direction * curSpeed, 0.1)
        
        local smoothedLook = car.PrimaryPart.CFrame.LookVector:Lerp(Vector3.new(direction.X, 0, direction.Z).Unit, 0.12)
        car.PrimaryPart.CFrame = car.PrimaryPart.CFrame:Lerp(CFrame.new(currentPos, currentPos + smoothedLook), 0.25)
        
        -- Ngăn xe rơi khỏi bản đồ
        local floorY = -30
        local resetY = -17
        if currentPos.Y < floorY then 
            car.PrimaryPart.CFrame = CFrame.new(currentPos.X, resetY, currentPos.Z) 
        end
        task.wait()
    end
end

-- Xử lý nhập tốc độ đua
speedInput.FocusLost:Connect(function(enterPressed)
    local num = tonumber(speedInput.Text)
    if num and num > 0 then
        targetSpeed = num
        statusText.Text = "Speed set to: " .. tostring(targetSpeed)
        statusText.TextColor3 = Color3.fromRGB(100, 255, 150)
    else
        speedInput.Text = tostring(targetSpeed)
        statusText.Text = "Vui lòng nhập tốc độ hợp lệ!"
        statusText.TextColor3 = Color3.fromRGB(255, 130, 130)
    end
end)

-- Vòng lặp điều hướng xe qua các checkpoint
local function startAutoRace()
    spawn(function()
        while autoRaceActive do
            task.wait(0.5)
            if not isPlayerSeated() then
                statusText.Text = "Status: Sit in a vehicle first!"
                statusText.TextColor3 = Color3.fromRGB(255, 130, 130)
                autoRaceActive = false
                toggleBtn.Text = "Auto Race: OFF"
                toggleBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 46)
                toggleStroke.Color = Color3.fromRGB(220, 55, 55)
                break
            end
            
            local car = getCar()
            if car and car.PrimaryPart then
                local checkpoints = getRaceCheckpoints()
                if #checkpoints > 0 then
                    statusText.Text = "Status: Found " .. #checkpoints .. " checkpoints. Driving..."
                    statusText.TextColor3 = Color3.fromRGB(100, 255, 150)
                    
                    stabilizeCar(car)
                    
                    for i, cp in ipairs(checkpoints) do
                        if not autoRaceActive or not isPlayerSeated() then break end
                        statusText.Text = "Status: Driving to CP " .. cp.Name .. " (" .. i .. "/" .. #checkpoints .. ")"
                        
                        local cpPos = cp:IsA("Model") and cp:GetPivot().Position or cp.Position
                        smoothNavigateToCar(car, cpPos, targetSpeed)
                    end
                    
                    if autoRaceActive then
                        statusText.Text = "Status: Race Completed Successfully!"
                        statusText.TextColor3 = Color3.fromRGB(100, 255, 150)
                        autoRaceActive = false
                        toggleBtn.Text = "Auto Race: OFF"
                        toggleBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 46)
                        toggleStroke.Color = Color3.fromRGB(220, 55, 55)
                        if carStabilizationConnection then 
                            carStabilizationConnection:Disconnect(); carStabilizationConnection = nil 
                        end
                    end
                else
                    statusText.Text = "Status: No checkpoints found. Start a race first!"
                    statusText.TextColor3 = Color3.fromRGB(255, 130, 130)
                    autoRaceActive = false
                    toggleBtn.Text = "Auto Race: OFF"
                    toggleBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 46)
                    toggleStroke.Color = Color3.fromRGB(220, 55, 55)
                end
            end
        end
    end)
end

-- Xử lý nút kích hoạt
toggleBtn.MouseButton1Click:Connect(function()
    if not isPlayerSeated() then
        statusText.Text = "Status: Sit in a vehicle first!"
        statusText.TextColor3 = Color3.fromRGB(255, 130, 130)
        return
    end

    autoRaceActive = not autoRaceActive
    if autoRaceActive then
        toggleBtn.Text = "Auto Race: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(26, 74, 36)
        toggleStroke.Color = Color3.fromRGB(100, 255, 150)
        statusText.Text = "Status: Scanning checkpoints..."
        statusText.TextColor3 = Color3.fromRGB(100, 255, 150)
        startAutoRace()
    else
        toggleBtn.Text = "Auto Race: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 46)
        toggleStroke.Color = Color3.fromRGB(220, 55, 55)
        statusText.Text = "Status: Ready (Manual Control)"
        statusText.TextColor3 = Color3.fromRGB(135, 135, 135)
        if carStabilizationConnection then 
            carStabilizationConnection:Disconnect(); carStabilizationConnection = nil 
        end
    end
end)

-- Hiệu ứng hover nút ON/OFF
toggleBtn.MouseEnter:Connect(function()
    TweenService:Create(toggleBtn, TweenInfo.new(0.2), {Size = UDim2.new(1, -20, 0, 42), Position = UDim2.new(0, 10, 0, 54)}):Play()
end)
toggleBtn.MouseLeave:Connect(function()
    TweenService:Create(toggleBtn, TweenInfo.new(0.2), {Size = UDim2.new(1, -24, 0, 40), Position = UDim2.new(0, 12, 0, 55)}):Play()
end)

-- Tính năng kéo thả GUI (Dragging)
local dragging, dragInput, dragStart, startPos
local dragConnection

guiFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = guiFrame.Position
        if dragConnection then dragConnection:Disconnect() end
        dragConnection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then 
                dragging = false 
                if dragConnection then 
                    dragConnection:Disconnect(); dragConnection = nil 
                end
            end 
        end)
    end
end)

guiFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then 
        dragInput = input 
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        guiFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
