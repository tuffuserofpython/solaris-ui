-- libui/components/ColorPicker.lua
-- Color picker component for LibUI

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local ColorPicker = {}
ColorPicker.__index = ColorPicker

local OPEN_INFO  = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local CLOSE_INFO = TweenInfo.new(0.20, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
local HOVER_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function hsvToColor(h, s, v)
	return Color3.fromHSV(h, s, v)
end

local function colorToHSV(color)
	return Color3.toHSV(color)
end

local function colorToHex(color)
	local r = math.floor(color.R * 255 + 0.5)
	local g = math.floor(color.G * 255 + 0.5)
	local b = math.floor(color.B * 255 + 0.5)
	return string.format("%02X%02X%02X", r, g, b)
end

local function hexToColor(hex)
	hex = hex:gsub("#", "")
	if #hex ~= 6 then return nil end
	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)
	if not r or not g or not b then return nil end
	return Color3.fromRGB(r, g, b)
end

--- Create a new color picker component
---@param parent GuiObject
---@param options table { Label, Default, Callback }
---@param theme table
---@return table ColorPicker object
function ColorPicker.new(parent: GuiObject, options: table, theme: table)
	assert(parent, "ColorPicker.new: parent is nil")

	local colors    = theme.Colors
	local fonts     = theme.Fonts
	local fontSizes = theme.FontSizes
	local radius    = theme.Radius
	local spacing   = theme.Spacing

	local self        = setmetatable({}, ColorPicker)
	self._theme       = theme
	self._connections = {}
	self._color       = options.Default or Color3.fromRGB(99, 102, 241)
	self._callback    = options.Callback
	self._destroyed   = false
	self._open        = false

	local h, s, v    = colorToHSV(self._color)
	self._h           = h
	self._s           = s
	self._v           = v
	self._opacity     = 1

	-- Row container
	local row = Instance.new("Frame")
	row.Name                   = "ColorPickerRow"
	row.Size                   = UDim2.new(1, 0, 0, 46)
	row.BackgroundTransparency = 1
	row.BorderSizePixel        = 0
	row.Parent                 = parent

	-- Hover bg
	local hoverBg = Instance.new("Frame")
	hoverBg.Name                   = "HoverBg"
	hoverBg.Size                   = UDim2.fromScale(1, 1)
	hoverBg.BackgroundColor3       = colors.Surface3
	hoverBg.BackgroundTransparency = 1
	hoverBg.BorderSizePixel        = 0
	hoverBg.Parent                 = row

	local hBgCorner = Instance.new("UICorner")
	hBgCorner.CornerRadius = UDim.new(0, radius.Small or 4)
	hBgCorner.Parent = hoverBg

	-- Label
	local label = Instance.new("TextLabel")
	label.Name                  = "Label"
	label.Size                  = UDim2.new(1, -60, 1, 0)
	label.Position              = UDim2.fromOffset(8, 0)
	label.BackgroundTransparency = 1
	label.Text                  = options.Label or "Color"
	label.TextColor3            = colors.Text
	label.TextSize              = fontSizes.Base or 13
	label.Font                  = fonts.Body
	label.TextXAlignment        = Enum.TextXAlignment.Left
	label.Parent                = row

	-- Color swatch button
	local swatchBtn = Instance.new("TextButton")
	swatchBtn.Name             = "SwatchBtn"
	swatchBtn.Size             = UDim2.fromOffset(38, 22)
	swatchBtn.Position         = UDim2.new(1, -46, 0.5, -11)
	swatchBtn.BackgroundColor3 = self._color
	swatchBtn.BorderSizePixel  = 0
	swatchBtn.Text             = ""
	swatchBtn.AutoButtonColor  = false
	swatchBtn.ZIndex           = row.ZIndex + 1
	swatchBtn.Parent           = row

	local swatchCorner = Instance.new("UICorner")
	swatchCorner.CornerRadius = UDim.new(0, radius.Small or 4)
	swatchCorner.Parent = swatchBtn

	local swatchStroke = Instance.new("UIStroke")
	swatchStroke.Color        = colors.Border
	swatchStroke.Transparency = theme.Transparency.Border or 0.07
	swatchStroke.Thickness    = 1
	swatchStroke.Parent       = swatchBtn

	self._row      = row
	self._swatch   = swatchBtn
	self._popover  = nil

	local function closePopover()
		if not self._open then return end
		self._open = false

		if self._popover then
			local pop = self._popover
			self._popover = nil
			TweenService:Create(pop, CLOSE_INFO, { BackgroundTransparency = 1 }):Play()
			task.delay(0.22, function()
				if pop and pop.Parent then pop:Destroy() end
			end)
		end
	end

	local function openPopover()
		if self._open then return end
		self._open = true

		local sg = row
		while sg and not sg:IsA("ScreenGui") do sg = sg.Parent end
		if not sg then return end

		local popW = 220
		local popH = 270

		local pop = Instance.new("Frame")
		pop.Name                   = "ColorPopover"
		pop.Size                   = UDim2.fromOffset(popW, popH)
		pop.Position               = UDim2.fromOffset(
			swatchBtn.AbsolutePosition.X - popW + swatchBtn.AbsoluteSize.X,
			swatchBtn.AbsolutePosition.Y + swatchBtn.AbsoluteSize.Y + 6
		)
		pop.BackgroundColor3       = colors.Surface2
		pop.BackgroundTransparency = 0
		pop.BorderSizePixel        = 0
		pop.ZIndex                 = 300
		pop.ClipsDescendants       = false
		pop.Parent                 = sg

		self._popover = pop

		local popCorner = Instance.new("UICorner")
		popCorner.CornerRadius = UDim.new(0, radius.Card or 8)
		popCorner.Parent = pop

		local popStroke = Instance.new("UIStroke")
		popStroke.Color        = colors.Border
		popStroke.Transparency = theme.Transparency.Border or 0.07
		popStroke.Thickness    = 1
		popStroke.Parent = pop

		local pad = 10

		-- Hue/Saturation 2D canvas
		local hsCursorSize = 12
		local canvasW = popW - pad * 2
		local canvasH = 120

		local hsCanvas = Instance.new("ImageLabel")
		hsCanvas.Name             = "HSCanvas"
		hsCanvas.Size             = UDim2.fromOffset(canvasW, canvasH)
		hsCanvas.Position         = UDim2.fromOffset(pad, pad)
		hsCanvas.BackgroundColor3 = hsvToColor(self._h, 1, 1)
		hsCanvas.Image            = "rbxassetid://0"
		hsCanvas.ZIndex           = 301
		hsCanvas.Parent           = pop

		-- Canvas showing saturation gradient (white → selected hue)
		-- White to transparent overlay
		local satGrad = Instance.new("UIGradient")
		satGrad.Color    = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
		})
		satGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		satGrad.Rotation = 0
		satGrad.Parent   = hsCanvas

		-- Black top-to-bottom overlay
		local brightOverlay = Instance.new("Frame")
		brightOverlay.Name             = "BrightOverlay"
		brightOverlay.Size             = UDim2.fromScale(1, 1)
		brightOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		brightOverlay.BackgroundTransparency = 0
		brightOverlay.BorderSizePixel  = 0
		brightOverlay.ZIndex           = 302
		brightOverlay.Parent           = hsCanvas

		local brightGrad = Instance.new("UIGradient")
		brightGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})
		brightGrad.Rotation = 90
		brightGrad.Parent   = brightOverlay

		local hsCorner = Instance.new("UICorner")
		hsCorner.CornerRadius = UDim.new(0, 4)
		hsCorner.Parent = hsCanvas

		-- HS cursor
		local hsCursor = Instance.new("Frame")
		hsCursor.Name             = "HSCursor"
		hsCursor.Size             = UDim2.fromOffset(hsCursorSize, hsCursorSize)
		hsCursor.AnchorPoint      = Vector2.new(0.5, 0.5)
		hsCursor.Position         = UDim2.new(self._s, 0, 1 - self._v, 0)
		hsCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		hsCursor.BorderSizePixel  = 0
		hsCursor.ZIndex           = 304
		hsCursor.Parent           = hsCanvas

		local hsCursorCorner = Instance.new("UICorner")
		hsCursorCorner.CornerRadius = UDim.new(1, 0)
		hsCursorCorner.Parent = hsCursor

		local hsCursorStroke = Instance.new("UIStroke")
		hsCursorStroke.Color     = Color3.fromRGB(0, 0, 0)
		hsCursorStroke.Transparency = 0.6
		hsCursorStroke.Thickness = 1
		hsCursorStroke.Parent    = hsCursor

		-- Hue slider
		local hueSliderY = pad + canvasH + 8
		local hueSlider = Instance.new("ImageLabel")
		hueSlider.Name             = "HueSlider"
		hueSlider.Size             = UDim2.fromOffset(canvasW, 12)
		hueSlider.Position         = UDim2.fromOffset(pad, hueSliderY)
		hueSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		hueSlider.Image            = "rbxassetid://0"
		hueSlider.ZIndex           = 301
		hueSlider.Parent           = pop

		local hueGrad = Instance.new("UIGradient")
		hueGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,     Color3.fromHSV(0,   1, 1)),
			ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
			ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
			ColorSequenceKeypoint.new(0.5,   Color3.fromHSV(0.5, 1, 1)),
			ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
			ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
			ColorSequenceKeypoint.new(1,     Color3.fromHSV(1,   1, 1)),
		})
		hueGrad.Parent = hueSlider

		local hueCorner = Instance.new("UICorner")
		hueCorner.CornerRadius = UDim.new(0, 6)
		hueCorner.Parent = hueSlider

		-- Hue cursor
		local hueCursor = Instance.new("Frame")
		hueCursor.Name             = "HueCursor"
		hueCursor.Size             = UDim2.fromOffset(8, 16)
		hueCursor.AnchorPoint      = Vector2.new(0.5, 0.5)
		hueCursor.Position         = UDim2.new(self._h, 0, 0.5, 0)
		hueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		hueCursor.BorderSizePixel  = 0
		hueCursor.ZIndex           = 303
		hueCursor.Parent           = hueSlider

		local hueCursorCorner = Instance.new("UICorner")
		hueCursorCorner.CornerRadius = UDim.new(0, 2)
		hueCursorCorner.Parent = hueCursor

		local hueCursorStroke = Instance.new("UIStroke")
		hueCursorStroke.Color     = Color3.fromRGB(0, 0, 0)
		hueCursorStroke.Transparency = 0.6
		hueCursorStroke.Thickness = 1
		hueCursorStroke.Parent    = hueCursor

		-- Value/Brightness slider
		local valSliderY = hueSliderY + 12 + 8
		local valBg = Instance.new("Frame")
		valBg.Name             = "ValBg"
		valBg.Size             = UDim2.fromOffset(canvasW, 12)
		valBg.Position         = UDim2.fromOffset(pad, valSliderY)
		valBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		valBg.BorderSizePixel  = 0
		valBg.ZIndex           = 301
		valBg.Parent           = pop

		local valGrad = Instance.new("UIGradient")
		valGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
		})
		valGrad.Parent = valBg

		local valCorner = Instance.new("UICorner")
		valCorner.CornerRadius = UDim.new(0, 6)
		valCorner.Parent = valBg

		local valCursor = Instance.new("Frame")
		valCursor.Name             = "ValCursor"
		valCursor.Size             = UDim2.fromOffset(8, 16)
		valCursor.AnchorPoint      = Vector2.new(0.5, 0.5)
		valCursor.Position         = UDim2.new(self._v, 0, 0.5, 0)
		valCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		valCursor.BorderSizePixel  = 0
		valCursor.ZIndex           = 303
		valCursor.Parent           = valBg

		local vCursorCorner = Instance.new("UICorner")
		vCursorCorner.CornerRadius = UDim.new(0, 2)
		vCursorCorner.Parent = valCursor

		local vCursorStroke = Instance.new("UIStroke")
		vCursorStroke.Color     = Color3.fromRGB(0, 0, 0)
		vCursorStroke.Transparency = 0.6
		vCursorStroke.Thickness = 1
		vCursorStroke.Parent    = valCursor

		-- Hex input row
		local hexY = valSliderY + 12 + 10

		local hexContainer = Instance.new("Frame")
		hexContainer.Name             = "HexContainer"
		hexContainer.Size             = UDim2.fromOffset(canvasW, 28)
		hexContainer.Position         = UDim2.fromOffset(pad, hexY)
		hexContainer.BackgroundColor3 = colors.Surface3
		hexContainer.BorderSizePixel  = 0
		hexContainer.ZIndex           = 301
		hexContainer.Parent           = pop

		local hexCor = Instance.new("UICorner")
		hexCor.CornerRadius = UDim.new(0, 4)
		hexCor.Parent = hexContainer

		local hexLabel = Instance.new("TextLabel")
		hexLabel.Name                  = "HexLabel"
		hexLabel.Size                  = UDim2.fromOffset(18, 28)
		hexLabel.Position              = UDim2.fromOffset(8, 0)
		hexLabel.BackgroundTransparency = 1
		hexLabel.Text                  = "#"
		hexLabel.TextColor3            = colors.TextMuted
		hexLabel.TextSize              = fontSizes.Sm or 12
		hexLabel.Font                  = fonts.Mono or fonts.Body
		hexLabel.ZIndex                = 302
		hexLabel.Parent                = hexContainer

		local hexInput = Instance.new("TextBox")
		hexInput.Name               = "HexInput"
		hexInput.Size               = UDim2.new(1, -28, 1, 0)
		hexInput.Position           = UDim2.fromOffset(22, 0)
		hexInput.BackgroundTransparency = 1
		hexInput.Text               = colorToHex(self._color)
		hexInput.TextColor3         = colors.Text
		hexInput.PlaceholderColor3  = colors.TextMuted
		hexInput.TextSize           = fontSizes.Sm or 12
		hexInput.Font               = fonts.Mono or fonts.Body
		hexInput.ClearTextOnFocus   = false
		hexInput.ZIndex             = 302
		hexInput.Parent             = hexContainer

		-- Current color preview
		local previewY = hexY + 28 + 8
		local previewFrame = Instance.new("Frame")
		previewFrame.Name             = "Preview"
		previewFrame.Size             = UDim2.fromOffset(canvasW, 22)
		previewFrame.Position         = UDim2.fromOffset(pad, previewY)
		previewFrame.BackgroundColor3 = self._color
		previewFrame.BorderSizePixel  = 0
		previewFrame.ZIndex           = 301
		previewFrame.Parent           = pop

		local previewCorner = Instance.new("UICorner")
		previewCorner.CornerRadius = UDim.new(0, 4)
		previewCorner.Parent = previewFrame

		-- Update all visuals
		local function updateAll()
			local newColor = hsvToColor(self._h, self._s, self._v)
			self._color = newColor
			swatchBtn.BackgroundColor3     = newColor
			previewFrame.BackgroundColor3  = newColor
			hsCanvas.BackgroundColor3      = hsvToColor(self._h, 1, 1)
			hsCursor.Position              = UDim2.new(self._s, 0, 1 - self._v, 0)
			hueCursor.Position             = UDim2.new(self._h, 0, 0.5, 0)
			valCursor.Position             = UDim2.new(self._v, 0, 0.5, 0)
			hexInput.Text                  = colorToHex(newColor)
			if self._callback then
				task.spawn(self._callback, newColor)
			end
		end

		-- HS Canvas drag
		local hsDragging = false

		local hsMoveConn = UserInputService.InputChanged:Connect(function(input)
			if hsDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				local absPos  = hsCanvas.AbsolutePosition
				local absSize = hsCanvas.AbsoluteSize
				local s = math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
				local v = 1 - math.clamp((input.Position.Y - absPos.Y) / absSize.Y, 0, 1)
				self._s = s
				self._v = v
				updateAll()
			end
		end)

		local hsPressConn = hsCanvas.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				hsDragging = true
				local absPos  = hsCanvas.AbsolutePosition
				local absSize = hsCanvas.AbsoluteSize
				local s = math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
				local v = 1 - math.clamp((input.Position.Y - absPos.Y) / absSize.Y, 0, 1)
				self._s = s
				self._v = v
				updateAll()
			end
		end)

		local hsReleaseConn = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				hsDragging = false
			end
		end)

		-- Hue slider drag
		local hueDragging = false

		local hueSliderMoveConn = UserInputService.InputChanged:Connect(function(input)
			if hueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				local absPos  = hueSlider.AbsolutePosition
				local absSize = hueSlider.AbsoluteSize
				self._h = math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
				updateAll()
			end
		end)

		local huePressConn = hueSlider.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				hueDragging = true
				local absPos  = hueSlider.AbsolutePosition
				local absSize = hueSlider.AbsoluteSize
				self._h = math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
				updateAll()
			end
		end)

		local hueEndConn = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				hueDragging = false
			end
		end)

		-- Value slider drag
		local valDragging = false

		local valMoveConn = UserInputService.InputChanged:Connect(function(input)
			if valDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				local absPos  = valBg.AbsolutePosition
				local absSize = valBg.AbsoluteSize
				self._v = math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
				updateAll()
			end
		end)

		local valPressConn = valBg.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				valDragging = true
				local absPos  = valBg.AbsolutePosition
				local absSize = valBg.AbsoluteSize
				self._v = math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
				updateAll()
			end
		end)

		local valEndConn = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				valDragging = false
			end
		end)

		-- Hex input
		local hexFocusLostConn = hexInput.FocusLost:Connect(function()
			local hex = hexInput.Text:gsub("#", "")
			local parsed = hexToColor(hex)
			if parsed then
				self._color = parsed
				local nh, ns, nv = colorToHSV(parsed)
				self._h = nh
				self._s = ns
				self._v = nv
				updateAll()
			else
				hexInput.Text = colorToHex(self._color)
			end
		end)

		-- Track all local connections for cleanup
		local popConnections = {
			hsMoveConn, hsPressConn, hsReleaseConn,
			hueSliderMoveConn, huePressConn, hueEndConn,
			valMoveConn, valPressConn, valEndConn,
			hexFocusLostConn,
		}

		-- Override close to also disconnect local conns
		local originalClose = closePopover
		self._closePopoverLocal = function()
			for _, c in ipairs(popConnections) do c:Disconnect() end
			table.clear(popConnections)
			originalClose()
		end

		-- Outside click to close
		local outsideConn
		outsideConn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local pos    = input.Position
				local popAbs = pop.AbsolutePosition
				local popSz  = pop.AbsoluteSize
				local bAbs   = swatchBtn.AbsolutePosition
				local bSz    = swatchBtn.AbsoluteSize
				local inPop  = pos.X >= popAbs.X and pos.X <= popAbs.X + popSz.X
					and pos.Y >= popAbs.Y and pos.Y <= popAbs.Y + popSz.Y
				local inBtn  = pos.X >= bAbs.X and pos.X <= bAbs.X + bSz.X
					and pos.Y >= bAbs.Y and pos.Y <= bAbs.Y + bSz.Y
				if not inPop and not inBtn then
					outsideConn:Disconnect()
					table.insert(popConnections, outsideConn)
					if self._closePopoverLocal then
						self._closePopoverLocal()
					else
						closePopover()
					end
				end
			end
		end)
	end

	-- Hover row
	local rowHoverConn = row.MouseEnter:Connect(function()
		TweenService:Create(hoverBg, HOVER_INFO, { BackgroundTransparency = 0.94 }):Play()
	end)

	local rowLeaveConn = row.MouseLeave:Connect(function()
		TweenService:Create(hoverBg, HOVER_INFO, { BackgroundTransparency = 1 }):Play()
	end)

	-- Toggle popover on swatch click
	local swatchClickConn = swatchBtn.MouseButton1Click:Connect(function()
		if self._open then
			if self._closePopoverLocal then
				self._closePopoverLocal()
			else
				closePopover()
			end
		else
			openPopover()
		end
	end)

	table.insert(self._connections, rowHoverConn)
	table.insert(self._connections, rowLeaveConn)
	table.insert(self._connections, swatchClickConn)

	self._closePopover = closePopover

	return self
end

--- Set color value
---@param color Color3
function ColorPicker:Set(color: Color3)
	self._color = color
	local h, s, v = colorToHSV(color)
	self._h = h
	self._s = s
	self._v = v
	self._swatch.BackgroundColor3 = color
end

--- Get current color value
---@return Color3
function ColorPicker:Get(): Color3
	return self._color
end

--- Destroy the color picker component
function ColorPicker:Destroy()
	if self._destroyed then return end
	self._destroyed = true

	if self._open then
		if self._closePopoverLocal then
			self._closePopoverLocal()
		else
			self._closePopover()
		end
	end

	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)

	if self._row then
		self._row:Destroy()
	end
end

return ColorPicker
