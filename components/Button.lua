-- libui/components/Button.lua
-- Button component with ripple effect for LibUI

local TweenService = game:GetService("TweenService")
local Ripple       = require(script.Parent.Parent.animations.Ripple)

local Button = {}
Button.__index = Button

local HOVER_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local PRESS_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local STYLE_CONFIGS = {
	primary   = { useFill = true,  useAccent = true,  textWhite = true  },
	secondary = { useFill = false, useAccent = false, textWhite = false },
	danger    = { useFill = true,  useDanger = true,  textWhite = true  },
	ghost     = { useFill = false, useAccent = false, textWhite = false, ghost = true },
}

--- Create a new button component
---@param parent GuiObject
---@param options table { Label, Description, Icon, Style, Callback }
---@param theme table
---@return table Button object
function Button.new(parent: GuiObject, options: table, theme: table)
	assert(parent, "Button.new: parent is nil")

	local colors    = theme.Colors
	local fonts     = theme.Fonts
	local fontSizes = theme.FontSizes
	local spacing   = theme.Spacing
	local radius    = theme.Radius
	local btnCfg    = (theme.Components and theme.Components.Button) or { Height = 34, PaddingH = 14, IconSize = 16 }

	local style     = options.Style or "secondary"
	local styleCfg  = STYLE_CONFIGS[style] or STYLE_CONFIGS.secondary

	local self        = setmetatable({}, Button)
	self._theme       = theme
	self._connections = {}
	self._enabled     = true
	self._callback    = options.Callback
	self._destroyed   = false
	self._style       = style
	self._styleCfg    = styleCfg

	-- Determine colors based on style
	local bgColor, bgHoverColor, bgPressColor, textColor, textHoverColor

	if styleCfg.useDanger then
		bgColor      = colors.Danger
		bgHoverColor = colors.DangerHover or colors.Danger
		bgPressColor = colors.DangerPress or colors.Danger
		textColor    = colors.White
		textHoverColor = colors.White
	elseif styleCfg.useAccent then
		bgColor      = colors.Accent
		bgHoverColor = colors.AccentHover or colors.Accent
		bgPressColor = colors.AccentPress or colors.Accent
		textColor    = colors.White
		textHoverColor = colors.White
	elseif styleCfg.ghost then
		bgColor      = Color3.fromRGB(0, 0, 0)
		bgHoverColor = colors.Surface3
		bgPressColor = colors.Surface2
		textColor    = colors.TextSub
		textHoverColor = colors.Text
	else
		-- secondary
		bgColor      = colors.Surface2
		bgHoverColor = colors.Surface3
		bgPressColor = colors.Surface
		textColor    = colors.Text
		textHoverColor = colors.Text
	end

	self._bgColor      = bgColor
	self._bgHoverColor = bgHoverColor
	self._bgPressColor = bgPressColor
	self._textColor    = textColor

	-- Row wrapper for description
	local hasDesc = options.Description and #options.Description > 0
	local rowH    = hasDesc and 58 or btnCfg.Height

	local row = Instance.new("Frame")
	row.Name                   = "ButtonRow"
	row.Size                   = UDim2.new(1, 0, 0, rowH)
	row.BackgroundTransparency = 1
	row.BorderSizePixel        = 0
	row.Parent                 = parent

	if hasDesc then
		local labelLabel = Instance.new("TextLabel")
		labelLabel.Name                  = "Label"
		labelLabel.Size                  = UDim2.new(1, 0, 0, 18)
		labelLabel.Position              = UDim2.fromOffset(spacing.Sm or 8, 6)
		labelLabel.BackgroundTransparency = 1
		labelLabel.Text                  = options.Label or ""
		labelLabel.TextColor3            = colors.Text
		labelLabel.TextSize              = fontSizes.Base or 13
		labelLabel.Font                  = fonts.Body
		labelLabel.TextXAlignment        = Enum.TextXAlignment.Left
		labelLabel.Parent                = row

		local desc = Instance.new("TextLabel")
		desc.Name                   = "Description"
		desc.Size                   = UDim2.new(1, 0, 0, 13)
		desc.Position               = UDim2.fromOffset(spacing.Sm or 8, 25)
		desc.BackgroundTransparency = 1
		desc.Text                   = options.Description
		desc.TextColor3             = colors.TextMuted
		desc.TextSize               = fontSizes.Xs or 10
		desc.Font                   = fonts.Caption
		desc.TextXAlignment         = Enum.TextXAlignment.Left
		desc.Parent                 = row
	end

	-- Button frame
	local btnY    = hasDesc and 42 or 0
	local btnH    = btnCfg.Height
	local btnSize = hasDesc
		and UDim2.new(1, -16, 0, btnH)
		or  UDim2.new(1, 0, 0, btnH)
	local btnPos  = hasDesc
		and UDim2.fromOffset(8, btnY)
		or  UDim2.fromOffset(0, 0)

	local btn = Instance.new("TextButton")
	btn.Name                   = "Btn"
	btn.Size                   = btnSize
	btn.Position               = btnPos
	btn.BackgroundColor3       = bgColor
	btn.BackgroundTransparency = styleCfg.ghost and 1 or 0
	btn.BorderSizePixel        = 0
	btn.Text                   = ""
	btn.AutoButtonColor        = false
	btn.ClipsDescendants       = true
	btn.ZIndex                 = row.ZIndex + 1
	btn.Parent                 = row

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, radius.Button or 6)
	btnCorner.Parent = btn

	-- Border for secondary/ghost
	if not styleCfg.useFill or styleCfg.ghost then
		local stroke = Instance.new("UIStroke")
		stroke.Color        = style == "ghost" and colors.Border or colors.Border
		stroke.Transparency = theme.Transparency.Border or 0.07
		stroke.Thickness    = 1
		stroke.Parent       = btn
		self._stroke = stroke
	end

	-- Content layout
	local contentFrame = Instance.new("Frame")
	contentFrame.Name                   = "Content"
	contentFrame.Size                   = UDim2.fromScale(1, 1)
	contentFrame.BackgroundTransparency = 1
	contentFrame.ZIndex                 = btn.ZIndex + 1
	contentFrame.Parent                 = btn

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.FillDirection       = Enum.FillDirection.Horizontal
	contentLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
	contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	contentLayout.Padding             = UDim.new(0, 6)
	contentLayout.Parent              = contentFrame

	-- Icon (optional)
	if options.Icon and #options.Icon > 0 then
		local iconSize = btnCfg.IconSize or 16
		local icon = Instance.new("ImageLabel")
		icon.Name                  = "Icon"
		icon.Size                  = UDim2.fromOffset(iconSize, iconSize)
		icon.BackgroundTransparency = 1
		icon.Image                 = options.Icon
		icon.ImageColor3           = textColor
		icon.ZIndex                = contentFrame.ZIndex + 1
		icon.Parent                = contentFrame
		self._icon = icon
	end

	-- Label
	local label = Instance.new("TextLabel")
	label.Name                  = "Label"
	label.Size                  = UDim2.fromOffset(0, btnH)
	label.AutomaticSize         = Enum.AutomaticSize.X
	label.BackgroundTransparency = 1
	label.Text                  = options.Label or "Button"
	label.TextColor3            = textColor
	label.TextSize              = fontSizes.Base or 13
	label.Font                  = fonts.SemiBold or fonts.Heading
	label.ZIndex                = contentFrame.ZIndex + 1
	label.Parent                = contentFrame

	self._row   = row
	self._btn   = btn
	self._label = label

	-- Hover/Press effects
	local hoverConn = btn.MouseEnter:Connect(function()
		if not self._enabled then return end
		if styleCfg.ghost then
			TweenService:Create(btn, HOVER_INFO, { BackgroundTransparency = 0.93 }):Play()
		else
			TweenService:Create(btn, HOVER_INFO, { BackgroundColor3 = bgHoverColor }):Play()
		end
		TweenService:Create(label, HOVER_INFO, { TextColor3 = textHoverColor }):Play()
		if self._icon then
			TweenService:Create(self._icon, HOVER_INFO, { ImageColor3 = textHoverColor }):Play()
		end
	end)

	local leaveConn = btn.MouseLeave:Connect(function()
		if not self._enabled then return end
		if styleCfg.ghost then
			TweenService:Create(btn, HOVER_INFO, { BackgroundTransparency = 1 }):Play()
		else
			TweenService:Create(btn, HOVER_INFO, { BackgroundColor3 = bgColor }):Play()
		end
		TweenService:Create(label, HOVER_INFO, { TextColor3 = textColor }):Play()
		if self._icon then
			TweenService:Create(self._icon, HOVER_INFO, { ImageColor3 = textColor }):Play()
		end
	end)

	local pressConn = btn.MouseButton1Down:Connect(function()
		if not self._enabled then return end
		if styleCfg.ghost then
			TweenService:Create(btn, PRESS_INFO, { BackgroundTransparency = 0.88 }):Play()
		else
			TweenService:Create(btn, PRESS_INFO, { BackgroundColor3 = bgPressColor }):Play()
		end
	end)

	local releaseConn = btn.MouseButton1Up:Connect(function()
		if not self._enabled then return end
		if styleCfg.ghost then
			TweenService:Create(btn, HOVER_INFO, { BackgroundTransparency = 0.93 }):Play()
		else
			TweenService:Create(btn, HOVER_INFO, { BackgroundColor3 = bgHoverColor }):Play()
		end
	end)

	local clickConn = btn.MouseButton1Click:Connect(function(x, y)
		if not self._enabled then return end

		-- Ripple effect
		local rippleColor = styleCfg.useAccent or styleCfg.useDanger
			and colors.White
			or colors.White
		Ripple.play(btn, x, y, rippleColor, styleCfg.useFill and 0.3 or 0.25)

		if self._callback then
			task.spawn(self._callback)
		end
	end)

	table.insert(self._connections, hoverConn)
	table.insert(self._connections, leaveConn)
	table.insert(self._connections, pressConn)
	table.insert(self._connections, releaseConn)
	table.insert(self._connections, clickConn)

	return self
end

--- Set the button label text
---@param text string
function Button:SetLabel(text: string)
	self._label.Text = text
end

--- Enable or disable the button
---@param enabled boolean
function Button:SetEnabled(enabled: boolean)
	self._enabled = enabled
	local colors = self._theme.Colors

	if enabled then
		self._btn.BackgroundColor3 = self._bgColor
		self._label.TextColor3     = self._textColor
		self._btn.BackgroundTransparency = self._styleCfg.ghost and 1 or 0
	else
		self._btn.BackgroundColor3 = colors.Surface2
		self._label.TextColor3     = colors.TextMuted
		if self._icon then
			self._icon.ImageColor3 = colors.TextMuted
		end
	end
end

--- Destroy the button component
function Button:Destroy()
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

return Button
