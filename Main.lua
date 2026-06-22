local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==========================================
-- ⚙️ [ตั้งค่าความแรงปุ่มที่ 1] ปรับตัวเลขได้ตามใจชอบ
-- ==========================================
local DETECTION_THRESHOLD = 150 -- ขีดจำกัดความเร็วตรวจจับแรงสะท้อน
local UPWARD_BOOST_FORCE = 350   -- แรงพุ่งขึ้นฟ้าแกน Y
local TWIST_FORCE = 20           -- แรงหมุนแกน X, Z เล็กน้อยเพื่อให้เอียงคว้าง

-- ==========================================
-- ⚙️ [ตั้งค่าความแรงปุ่มที่ 2] แรงพุ่งดิ่งเฉียบพลัน 0.0001 วิ
-- ==========================================
local SPEED_FORCE_200 = -200    -- ความเร็วพุ่งดิ่งลงล่างแกน Y (-200 studs/s)

-- สร้าง ScreenGui หลักร่วมกัน
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClarityFlingGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- ฟังก์ชันส่วนกลางสำหรับทำให้ปุ่มลากย้ายตำแหน่งได้ (Draggable UI)
local function makeDraggable(targetButton)
	local dragging = false
	local dragInput, dragStart, startPos
	local dragDistance = 0 

	local function update(input)
		local delta = input.Position - dragStart
		targetButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		dragDistance = delta.Magnitude 
	end

	targetButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = targetButton.Position
			dragDistance = 0 
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)

	targetButton.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then update(input) end
	end)
	
	return function()
		return dragDistance
	end
end

-- ==========================================
-- 🟢 BUTTON 1: ระบบตรวจจับแรงสะท้อนแล้วดีดขึ้นฟ้า (Y-SPIN Toggle)
-- ==========================================
local btn1 = Instance.new("TextButton")
btn1.Name = "YSpinButton"
btn1.Size = UDim2.new(0, 85, 0, 85) 
btn1.Position = UDim2.new(0.4, -42, 0.5, -42) -- ฝั่งซ้าย
btn1.BackgroundColor3 = Color3.fromRGB(150, 30, 30) -- สีแดงเข้ม (อ่านง่าย สบายตา)
btn1.Text = "Y-SPIN\n[OFF]"
btn1.TextColor3 = Color3.fromRGB(255, 255, 255)
btn1.Font = Enum.Font.SourceSansBold
btn1.TextSize = 14
btn1.AutoButtonColor = false
btn1.Parent = screenGui

local corner1 = Instance.new("UICorner", btn1)
corner1.CornerRadius = UDim.new(1, 0)
local stroke1 = Instance.new("UIStroke", btn1)
stroke1.Thickness = 2.5
stroke1.Color = Color3.fromRGB(40, 40, 40) -- ขอบมืดตัดสีกราฟิกให้ตัวอักษรเด่น

local getDragDistance1 = makeDraggable(btn1)
local isYSpinEnabled = false
local lastVelocity = Vector3.new(0, 0, 0)

btn1.Activated:Connect(function()
	if getDragDistance1() < 10 then
		isYSpinEnabled = not isYSpinEnabled
		if isYSpinEnabled then
			btn1.BackgroundColor3 = Color3.fromRGB(30, 130, 30) -- สีเขียวเข้มทึบ ไม่สว่างจ้า
			btn1.Text = "Y-SPIN\n[ON]"
		else
			btn1.BackgroundColor3 = Color3.fromRGB(150, 30, 30) -- กลับเป็นสีแดงเข้ม
			btn1.Text = "Y-SPIN\n[OFF]"
		end
	end
end)

-- Loop ระบบปุ่มที่ 1 ตรวจแรงสะท้อน
RunService.Heartbeat:Connect(function()
	if not isYSpinEnabled then return end
	local character = player.Character if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart") if not rootPart then return end
	
	local currentVelocity = rootPart.AssemblyLinearVelocity
	if math.abs(currentVelocity.X) > DETECTION_THRESHOLD or math.abs(currentVelocity.Y) > DETECTION_THRESHOLD or math.abs(currentVelocity.Z) > DETECTION_THRESHOLD then
		if (currentVelocity - lastVelocity).Magnitude > 50 then
			local randomX = (math.random() * 2 - 1) * TWIST_FORCE
			local randomZ = (math.random() * 2 - 1) * TWIST_FORCE
			rootPart.AssemblyAngularVelocity = Vector3.new(randomX, 0, randomZ)
			rootPart.AssemblyLinearVelocity = Vector3.new(0, UPWARD_BOOST_FORCE, 0)
		end
	end
	lastVelocity = currentVelocity
end)


-- ==========================================
-- 🔵 BUTTON 2: ปุ่มกดพุ่งดิ่งความเร็ว -200 ทันที (เสร็จสิ้นการทำงานใน 0.0001 วิ)
-- ==========================================
local btn2 = Instance.new("TextButton")
btn2.Name = "InstantDropButton"
btn2.Size = UDim2.new(0, 85, 0, 85) 
btn2.Position = UDim2.new(0.6, -42, 0.5, -42) -- ฝั่งขวา
btn2.BackgroundColor3 = Color3.fromRGB(45, 45, 45) -- สีเทาเข้มคลาสสิก ตัวหนังสือเด่นชัดอ่านง่ายมาก
btn2.Text = "FAST DROP\n[-200]"
btn2.TextColor3 = Color3.fromRGB(255, 255, 255)
btn2.Font = Enum.Font.SourceSansBold
btn2.TextSize = 13
btn2.AutoButtonColor = true -- มีอนิเมชั่นยุบลงตอนคลิกชัดเจน
btn2.Parent = screenGui

local corner2 = Instance.new("UICorner", btn2)
corner2.CornerRadius = UDim.new(1, 0)
local stroke2 = Instance.new("UIStroke", btn2)
stroke2.Thickness = 2.5
stroke2.Color = Color3.fromRGB(255, 255, 255)

local getDragDistance2 = makeDraggable(btn2)

-- ทำงานแบบ Instant ทันทีที่แตะกดปุ่ม และจบกระบวนการอย่างสมบูรณ์ในพริบตา
btn2.Activated:Connect(function()
	if getDragDistance2() < 10 then -- เช็คว่าคลิกสั้นๆ ไม่ใช่ลากปุ่มย้ายจอ
		local character = player.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				-- สั่งจ่ายความเร็วลงล่าง -200 studs/s ทันทีในเฟรมปัจจุบัน 
				-- ฟิสิกส์ถูกป้อนอย่างแม่นยำและเสร็จสิ้นขั้นตอนแบบ Real-time ต่ำกว่า 0.0001 วินาที
				rootPart.AssemblyLinearVelocity = Vector3.new(
					rootPart.AssemblyLinearVelocity.X,
					SPEED_FORCE_200,
					rootPart.AssemblyLinearVelocity.Z
				)
			end
		end
	end
end)
