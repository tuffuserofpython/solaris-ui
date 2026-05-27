-- libui/components/Toggle.lua
-- iOS-style toggle switch component for LibUI

local TweenService = game:GetService("TweenService")

local Toggle = {}
Toggle.__index = Toggle

local HOVER_INFO      = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TOGGLE_INFO     = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

--- Create a new toggle component
---@param parent GuiObject
---@param options table { Label, Description, Default, Callback }
---@param theme table
---@return table Toggle object
function Toggle.new(parent: GuiObject, options: table, theme: table)
	assert(parent, "Toggle.new: parent is nil")

	local colors    = theme.Colors
	local fonts     = theme.Fonts
	local fontSizes = theme.FontSizes
	local spacing   = theme.Spacing
	local radius    = theme.Radius

	local togCfg = (theme.Components and theme.Components.Toggle) or {
		Width = 42, Height = 24, Thumb = 18, Padding = 3,
	}

	local self        = setmetatable({}, Toggle)
	self._theme       = theme
	self._connections = {}
	self._value       = options.Default == true
	self._callback    = options.Callback
	self._destroyed   = false

	-- Calculate row height
	local rowH = options.Description and #options.Description > 0 and 52 or 46

	-- Row container
	local row = Instance.new("Frame")
	row.Name                   = "ToggleRow"
	row.Size                   = UDim2.new(1, 0, 0, rowH)
	row.BackgroundTransparency = 1
	row.BorderSizePixel        = 0
	row.Parent                 = parent

	-- Hover background
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

	-- Label area
	local labelFrame = Instance.new("Frame")
	labelFrame.Name                   = "LabelFrame"
	labelFrame.Size                   = UDim2.new(1, -(togCfg.Width + 16), 1, 0)
	labelFrame.Position               = UDim2.fromOffset(spacing.Sm or 8, 0)
	labelFrame.BackgroundTransparency = 1
	labelFrame.Parent                 = row

	local labelY = options.Description and #options.Description > 0 and 8 or 0

	local label = Instance.new("TextLabel")
	label.Name                   = "Label"
	label.Size                   = UDim2.new(1, 0, 0, 18)
	label.Position               = options.Description and #options.Description > 0
		and UDim2.fromOffset(0, labelY)
		or  UDim2.new(0, 0, 0.5, -9)
	label.BackgroundTransparency = 1
	label.Text                   = options.Label or "Toggle"
	label.TextColor3             = colors.Text
	label.TextSize               = fontSizes.Base or 13
	label.Font                   = fonts.Body
	label.TextXAlignment         = Enum.TextXAlignment.Left
	label.Parent                 = labelFrame

	if options.Description and #options.Description > 0 then
		local desc = Instance.new("TextLabel")
		desc.Name                   = "Description"
		desc.Size                   = UDim2.new(1, 0, 0, 14)
		desc.Position               = UDim2.fromOffset(0, labelY + 20)
		desc.BackgroundTransparency = 1
		desc.Text                   = options.Description
		desc.TextColor3             = colors.TextMuted
		desc.TextSize               = fontSizes.Xs or 10
		desc.Font                   = fonts.Caption
		desc.TextXAlignment         = Enum.TextXAlignment.Left
		desc.Parent                 = labelFrame
	end

	-- Toggle pill background
	local pillBg = Instance.new("Frame")
	pillBg.Name             = "PillBg"
	pillBg.Size             = UDim2.fromOffset(togCfg.Width, togCfg.Height)
	pillBg.Position         = UDim2.new(1, -(togCfg.Width + 8), 0.5, -togCfg.Height / 2)
	pillBg.BackgroundColor3 = self._value and colors.Accent or colors.Surface3
	pillBg.BorderSizePixel  = 0
	pillBg.ZIndex           = row.ZIndex + 1
	pillBg.Parent           = row

	local pillCorner = Instance.new("UICorner")
	pillCorner.CornerRadius = UDim.new(0, togCfg.Height / 2)
	pillCorner.Parent = pillBg

	-- Thumb
	local thumbSize  = togCfg.Thumb
	local thumbPad   = togCfg.Padding
	local thumbOffX_off = thumbPad
	local thumbOffX_on  = togCfg.Width - thumbSize - thumbPad

	local thumb = Instance.new("Frame")
	thumb.Name             = "Thumb"
	thumb.Size             = UDim2.fromOffset(thumbSize, thumbSize)
	thumb.Position         = self._value
		and UDim2.fromOffset(thumbOffX_on,  (togCfg.Height - thumbSize) / 2)
		or  UDim2.fromOffset(thumbOffX_off, (togCfg.Height - thumbSize) / 2)
	thumb.BackgroundColor3 = colors.White
	thumb.BorderSizePixel  = 0
	thumb.ZIndex           = pillBg.ZIndex + 1
	thumb.Parent           = pillBg

	local thumbCorner = Instance.new("UICorner")
	thumbCorner.CornerRadius = UDim.new(1, 0)
	thumbCorner.Parent = thumb

	-- Invisible button over the whole row for click
	local clickBtn = Instance.new("TextButton")
	clickBtn.Name                   = "ClickBtn"
	clickBtn.Size                   = UDim2.fromScale(1, 1)
	clickBtn.BackgroundTransparency = 1
	clickBtn.Text                   = ""
	clickBtn.ZIndex                 = row.ZIndex + 5
	clickBtn.Parent                 = row

	self._row        = row
	self._pillBg     = pillBg
	self._thumb      = thumb
	self._thumbOffX_off = thumbOffX_off
	self._thumbOffX_on  = thumbOffX_on
	self._togCfg     = togCfg

	-- Hover effects
	local hoverConn = row.MouseEnter:Connect(function()
		TweenService:Create(hoverBg, HOVER_INFO, { BackgroundTransparency = 0.94 }):Play()
	end)

	local leaveConn = row.MouseLeave:Connect(function()
		TweenService:Create(hoverBg, HOVER_INFO, { BackgroundTransparency = 1 }):Play()
	end)

	-- Toggle on click
	local clickConn = clickBtn.MouseButton1Click:Connect(function()
		self:Set(not self._value)
	end)

	-- Press scale effect on thumb
	local pressConn = clickBtn.MouseButton1Down:Connect(function()
		TweenService:Create(thumb, HOVER_INFO, {
			Size = UDim2.fromOffset(thumbSize + 2, thumbSize + 2),
		}):Play()
	end)

	local releaseConn = clickBtn.MouseButton1Up:Connect(function()
		TweenService:Create(thumb, HOVER_INFO, {
			Size = UDim2.fromOffset(thumbSize, thumbSize),
		}):Play()
	end)

	table.insert(self._connections, hoverConn)
	table.insert(self._connections, leaveConn)
	table.insert(self._connections, clickConn)
	table.insert(self._connections, pressConn)
	table.insert(self._connections, releaseConn)

	return self
end

--- Set the toggle value
---@param value boolean
function Toggle:Set(value: boolean)
	self._value = value
	local colors = self._theme.Colors
	local togCfg = self._togCfg

	-- Animate pill color
	TweenService:Create(self._pillBg, TOGGLE_INFO, {
		BackgroundColor3 = value and colors.Accent or colors.Surface3,
	}):Play()

	-- Animate thumb position
	local targetX = value and self._thumbOffX_on or self._thumbOffX_off
	TweenService:Create(self._thumb, TOGGLE_INFO, {
		Position = UDim2.fromOffset(targetX, (togCfg.Height - togCfg.Thumb) / 2),
	}):Play()

	if self._callback then
		task.spawn(self._callback, value)
	end
end

--- Get the current toggle value
---@return boolean
function Toggle:Get(): boolean
	return self._value
end

--- Destroy the toggle component
function Toggle:Destroy()
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

return Toggle
