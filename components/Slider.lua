-- libui/components/Slider.lua
-- Drag slider component for LibUI

local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")

local Slider = {}
Slider.__index = Slider

local HOVER_INFO  = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local NORMAL_INFO = TweenInfo.new(0.20, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

--- Create a new slider component
---@param parent GuiObject
---@param options table { Label, Description, Min, Max, Default, Step, Suffix, Callback }
---@param theme table
---@return table Slider object
function Slider.new(parent: GuiObject, options: table, theme: table)
	assert(parent, "Slider.new: parent is nil")

	local colors    = theme.Colors
	local fonts     = theme.Fonts
	local fontSizes = theme.FontSizes
	local spacing   = theme.Spacing
	local radius    = theme.Radius

	local sliderCfg = (theme.Components and theme.Components.Slider) or {
		Height = 4, ThumbSize = 16, RowHeight = 48,
	}

	local min     = options.Min     or 0
	local max     = options.Max     or 100
	local step    = options.Step    or 1
	local default = options.Default or min
	local suffix  = options.Suffix  or ""

	-- Clamp default
	default = math.max(min, math.min(max, default))

	local self        = setmetatable({}, Slider)
	self._theme       = theme
	self._connections = {}
	self._value       = default
	self._min         = min
	self._max         = max
	self._step        = step
	self._suffix      = suffix
	self._callback    = options.Callback
	self._destroyed   = false
	self._dragging    = false

	local rowH = options.Description and #options.Description > 0 and 58 or 52

	-- Row container
	local row = Instance.new("Frame")
	row.Name                   = "SliderRow"
	row.Size                   = UDim2.new(1, 0, 0, rowH)
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
	hoverBg.ZIndex                 = row.ZIndex
	hoverBg.Parent                 = row

	local hoverCorner = Instance.new("UICorner")
	hoverCorner.CornerRadius = UDim.new(0, radius.Small or 4)
	hoverCorner.Parent = hoverBg

	-- Label row (top)
	local labelLabel = Instance.new("TextLabel")
	labelLabel.Name                  = "Label"
	labelLabel.Size                  = UDim2.new(1, -80, 0, 18)
	labelLabel.Position              = UDim2.fromOffset(spacing.Sm or 8, 8)
	labelLabel.BackgroundTransparency = 1
	labelLabel.Text                  = options.Label or "Slider"
	labelLabel.TextColor3            = colors.Text
	labelLabel.TextSize              = fontSizes.Base or 13
	labelLabel.Font                  = fonts.Body
	labelLabel.TextXAlignment        = Enum.TextXAlignment.Left
	labelLabel.Parent                = row

	-- Value label (top right)
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name                  = "ValueLabel"
	valueLabel.Size                  = UDim2.fromOffset(72, 18)
	valueLabel.Position              = UDim2.new(1, -80, 0, 8)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text                  = tostring(default) .. suffix
	valueLabel.TextColor3            = colors.Accent
	valueLabel.TextSize              = fontSizes.Sm or 12
	valueLabel.Font                  = fonts.SemiBold or fonts.Heading
	valueLabel.TextXAlignment        = Enum.TextXAlignment.Right
	valueLabel.Parent                = row

	if options.Description and #options.Description > 0 then
		local desc = Instance.new("TextLabel")
		desc.Name                   = "Description"
		desc.Size                   = UDim2.new(1, -16, 0, 13)
		desc.Position               = UDim2.fromOffset(spacing.Sm or 8, 27)
		desc.BackgroundTransparency = 1
		desc.Text                   = options.Description
		desc.TextColor3             = colors.TextMuted
		desc.TextSize               = fontSizes.Xs or 10
		desc.Font                   = fonts.Caption
		desc.TextXAlignment         = Enum.TextXAlignment.Left
		desc.Parent                 = row
	end

	local trackY = options.Description and #options.Description > 0 and 44 or 36

	-- Track background
	local trackBg = Instance.new("Frame")
	trackBg.Name             = "TrackBg"
	trackBg.Size             = UDim2.new(1, -16, 0, sliderCfg.Height)
	trackBg.Position         = UDim2.fromOffset(spacing.Sm or 8, trackY)
	trackBg.BackgroundColor3 = colors.Surface3
	trackBg.BorderSizePixel  = 0
	trackBg.ZIndex           = row.ZIndex + 1
	trackBg.Parent           = row

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = trackBg

	-- Track fill
	local trackFill = Instance.new("Frame")
	trackFill.Name             = "TrackFill"
	trackFill.Size             = UDim2.fromScale(0, 1)
	trackFill.BackgroundColor3 = colors.Accent
	trackFill.BorderSizePixel  = 0
	trackFill.ZIndex           = row.ZIndex + 2
	trackFill.Parent           = trackBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = trackFill

	-- Thumb
	local thumbSize = sliderCfg.ThumbSize
	local thumb = Instance.new("Frame")
	thumb.Name             = "Thumb"
	thumb.Size             = UDim2.fromOffset(thumbSize, thumbSize)
	thumb.AnchorPoint      = Vector2.new(0.5, 0.5)
	thumb.Position         = UDim2.new(0, 0, 0.5, 0)
	thumb.BackgroundColor3 = colors.White
	thumb.BorderSizePixel  = 0
	thumb.ZIndex           = row.ZIndex + 3
	thumb.Parent           = trackBg

	local thumbCorner = Instance.new("UICorner")
	thumbCorner.CornerRadius = UDim.new(1, 0)
	thumbCorner.Parent = thumb

	-- Thumb shadow effect
	local thumbStroke = Instance.new("UIStroke")
	thumbStroke.Color        = colors.Black
	thumbStroke.Transparency = 0.70
	thumbStroke.Thickness    = 1
	thumbStroke.Parent       = thumb

	-- Click area (extends above/below track for easier interaction)
	local hitArea = Instance.new("TextButton")
	hitArea.Name                   = "HitArea"
	hitArea.Size                   = UDim2.new(1, -16, 0, 20)
	hitArea.Position               = UDim2.fromOffset(spacing.Sm or 8, trackY - 8)
	hitArea.BackgroundTransparency = 1
	hitArea.Text                   = ""
	hitArea.ZIndex                 = row.ZIndex + 4
	hitArea.Parent                 = row

	self._row        = row
	self._trackBg    = trackBg
	self._trackFill  = trackFill
	self._thumb      = thumb
	self._valueLabel = valueLabel
	self._thumbSize  = thumbSize

	-- Set initial fill position
	self:_updateVisuals(default, false)

	-- Hover row effect
	local rowHoverConn = row.MouseEnter:Connect(function()
		TweenService:Create(hoverBg, HOVER_INFO, { BackgroundTransparency = 0.95 }):Play()
	end)

	local rowLeaveConn = row.MouseLeave:Connect(function()
		TweenService:Create(hoverBg, HOVER_INFO, { BackgroundTransparency = 1 }):Play()
	end)

	-- Thumb hover effects
	local thumbHoverConn = thumb.MouseEnter:Connect(function()
		TweenService:Create(thumb, HOVER_INFO, {
			Size = UDim2.fromOffset(thumbSize + 2, thumbSize + 2),
		}):Play()
	end)

	local thumbLeaveConn = thumb.MouseLeave:Connect(function()
		if not self._dragging then
			TweenService:Create(thumb, HOVER_INFO, {
				Size = UDim2.fromOffset(thumbSize, thumbSize),
			}):Play()
		end
	end)

	table.insert(self._connections, rowHoverConn)
	table.insert(self._connections, rowLeaveConn)
	table.insert(self._connections, thumbHoverConn)
	table.insert(self._connections, thumbLeaveConn)

	-- Drag logic
	local function onInput(input)
		if not self._dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then

			local absPos  = trackBg.AbsolutePosition
			local absSize = trackBg.AbsoluteSize
			local mouseX  = input.Position.X

			local t = math.clamp((mouseX - absPos.X) / absSize.X, 0, 1)
			local rawValue = min + t * (max - min)

			-- Apply step
			if step and step > 0 then
				rawValue = math.floor(rawValue / step + 0.5) * step
			end
			rawValue = math.clamp(rawValue, min, max)

			self:_updateVisuals(rawValue, false)
			self._value = rawValue
			valueLabel.Text = self:_formatValue(rawValue)

			if self._callback then
				task.spawn(self._callback, rawValue)
			end
		end
	end

	local function onInputEnded(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if self._dragging then
				self._dragging = false
				TweenService:Create(thumb, HOVER_INFO, {
					Size = UDim2.fromOffset(thumbSize, thumbSize),
				}):Play()
				TweenService:Create(trackFill, HOVER_INFO, {
					BackgroundColor3 = colors.Accent,
				}):Play()
			end
		end
	end

	local clickConn = hitArea.MouseButton1Down:Connect(function(x, y)
		self._dragging = true
		TweenService:Create(thumb, HOVER_INFO, {
			Size = UDim2.fromOffset(thumbSize + 4, thumbSize + 4),
		}):Play()
		TweenService:Create(trackFill, HOVER_INFO, {
			BackgroundColor3 = colors.AccentHover or colors.Accent,
		}):Play()

		-- Initial click position
		local absPos  = trackBg.AbsolutePosition
		local absSize = trackBg.AbsoluteSize
		local t = math.clamp((x - absPos.X) / absSize.X, 0, 1)
		local rawValue = min + t * (max - min)

		if step and step > 0 then
			rawValue = math.floor(rawValue / step + 0.5) * step
		end
		rawValue = math.clamp(rawValue, min, max)

		self:_updateVisuals(rawValue, false)
		self._value = rawValue
		valueLabel.Text = self:_formatValue(rawValue)

		if self._callback then
			task.spawn(self._callback, rawValue)
		end
	end)

	local moveConn   = UserInputService.InputChanged:Connect(onInput)
	local endConn    = UserInputService.InputEnded:Connect(onInputEnded)

	table.insert(self._connections, clickConn)
	table.insert(self._connections, moveConn)
	table.insert(self._connections, endConn)

	return self
end

--- Update visual state based on value
---@param value number
---@param animate boolean
function Slider:_updateVisuals(value: number, animate: boolean)
	local t = (value - self._min) / (self._max - self._min)
	t = math.clamp(t, 0, 1)

	local targetFillScale = UDim2.fromScale(t, 1)
	local targetThumbPos  = UDim2.new(t, 0, 0.5, 0)

	if animate then
		TweenService:Create(self._trackFill, NORMAL_INFO, { Size = targetFillScale }):Play()
		TweenService:Create(self._thumb, NORMAL_INFO, { Position = targetThumbPos }):Play()
	else
		self._trackFill.Size     = targetFillScale
		self._thumb.Position     = targetThumbPos
	end
end

--- Format a value for display
function Slider:_formatValue(value: number): string
	local colors = self._theme.Colors
	-- Round to avoid floating point display issues
	local decimals = 0
	if self._step < 1 then
		decimals = math.ceil(-math.log10(self._step))
	end
	local rounded = math.floor(value * (10^decimals) + 0.5) / (10^decimals)
	return tostring(rounded) .. self._suffix
end

--- Set slider value programmatically
---@param value number
function Slider:Set(value: number)
	value = math.clamp(value, self._min, self._max)
	if self._step and self._step > 0 then
		value = math.floor(value / self._step + 0.5) * self._step
		value = math.clamp(value, self._min, self._max)
	end
	self._value = value
	self._valueLabel.Text = self:_formatValue(value)
	self:_updateVisuals(value, true)
end

--- Get current slider value
---@return number
function Slider:Get(): number
	return self._value
end

--- Destroy the slider component
function Slider:Destroy()
	if self._destroyed then return end
	self._destroyed = true

	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)

	if self._row then
		self._row:Destroy()
	end
end

return Slider
