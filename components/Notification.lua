-- libui/components/Notification.lua
-- Notification manager component for LibUI

local TweenService = game:GetService("TweenService")

local Notification = {}
Notification.__index = Notification

local SLIDE_IN_INFO  = TweenInfo.new(0.35, Enum.EasingStyle.Quint,  Enum.EasingDirection.Out)
local FADE_IN_INFO   = TweenInfo.new(0.25, Enum.EasingStyle.Quart,  Enum.EasingDirection.Out)
local SLIDE_OUT_INFO = TweenInfo.new(0.28, Enum.EasingStyle.Quart,  Enum.EasingDirection.In)

local TYPE_CONFIG = {
	info    = { icon = "ℹ", color = nil },         -- uses Accent
	success = { icon = "✓", color = nil },         -- uses Success
	warning = { icon = "⚠", color = nil },         -- uses Warning
	error   = { icon = "✕", color = nil },         -- uses Danger
}

--- Create a new notifications manager
---@param container GuiObject Parent container (e.g. ScreenGui)
---@param theme table
---@return table Notification manager
function Notification.new(container: GuiObject, theme: table)
	assert(container, "Notification.new: container is nil")

	local self      = setmetatable({}, Notification)
	self._theme     = theme
	self._container = container
	self._items     = {}
	self._maxVisible = (theme.Components and theme.Components.Notification and theme.Components.Notification.MaxVisible) or 5

	-- Create the notification stack frame (bottom-right)
	local stack = Instance.new("Frame")
	stack.Name                  = "NotificationStack"
	stack.Size                  = UDim2.fromOffset(
		(theme.Components and theme.Components.Notification and theme.Components.Notification.Width) or 300,
		0
	)
	stack.Position              = UDim2.new(1, -16, 1, -16)
	stack.AnchorPoint           = Vector2.new(1, 1)
	stack.BackgroundTransparency = 1
	stack.ClipsDescendants      = false
	stack.ZIndex                = 500
	stack.Parent                = container

	-- Use a UIListLayout for stacking
	local layout = Instance.new("UIListLayout")
	layout.FillDirection       = Enum.FillDirection.Vertical
	layout.VerticalAlignment   = Enum.VerticalAlignment.Bottom
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.Padding             = UDim.new(0, (theme.Components and theme.Components.Notification and theme.Components.Notification.Gap) or 8)
	layout.Parent              = stack

	-- Resize stack automatically
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		stack.Size = UDim2.fromOffset(
			(theme.Components and theme.Components.Notification and theme.Components.Notification.Width) or 300,
			layout.AbsoluteContentSize.Y
		)
	end)

	self._stack  = stack
	self._layout = layout

	return self
end

--- Show a notification
---@param options table { Title, Message, Type, Duration }
function Notification:Notify(options: table)
	local colors    = self._theme.Colors
	local fonts     = self._theme.Fonts
	local fontSizes = self._theme.FontSizes
	local radius    = self._theme.Radius
	local spacing   = self._theme.Spacing

	local notifType = (options.Type or "info"):lower()
	local title     = options.Title   or ""
	local message   = options.Message or ""
	local duration  = options.Duration or 4

	-- Limit visible notifications
	while #self._items >= self._maxVisible do
		local oldest = self._items[1]
		if oldest then
			self:_dismissItem(oldest)
		end
	end

	-- Pick accent color
	local accentColor
	if notifType == "success" then
		accentColor = colors.Success
	elseif notifType == "warning" then
		accentColor = colors.Warning
	elseif notifType == "error" then
		accentColor = colors.Danger
	else
		accentColor = colors.Accent
	end

	local typeIcon = TYPE_CONFIG[notifType] and TYPE_CONFIG[notifType].icon or "ℹ"

	-- Notification width
	local notifWidth = (self._theme.Components and self._theme.Components.Notification and self._theme.Components.Notification.Width) or 300

	-- Create notification frame
	local frame = Instance.new("Frame")
	frame.Name                  = "Notification_" .. tostring(tick())
	frame.Size                  = UDim2.fromOffset(notifWidth, 0)
	frame.AutomaticSize         = Enum.AutomaticSize.Y
	frame.BackgroundColor3      = colors.Surface2
	frame.BackgroundTransparency = 0
	frame.BorderSizePixel       = 0
	frame.Position              = UDim2.fromOffset(notifWidth + 20, 0)  -- start off-screen right
	frame.ClipsDescendants      = false
	frame.ZIndex                = 501

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius.Card or 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color        = colors.Border
	stroke.Transparency = self._theme.Transparency.Border or 0.07
	stroke.Thickness    = 1
	stroke.Parent       = frame

	-- Left accent bar
	local accentBar = Instance.new("Frame")
	accentBar.Name             = "AccentBar"
	accentBar.Size             = UDim2.new(0, 3, 1, -8)
	accentBar.Position         = UDim2.fromOffset(4, 4)
	accentBar.BackgroundColor3 = accentColor
	accentBar.BorderSizePixel  = 0
	accentBar.ZIndex           = 502

	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 2)
	accentCorner.Parent = accentBar
	accentBar.Parent = frame

	-- Icon
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name                  = "Icon"
	iconLabel.Size                  = UDim2.fromOffset(24, 24)
	iconLabel.Position              = UDim2.fromOffset(14, 12)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text                  = typeIcon
	iconLabel.TextColor3            = accentColor
	iconLabel.TextSize              = 16
	iconLabel.Font                  = fonts.Heading
	iconLabel.ZIndex                = 502
	iconLabel.Parent                = frame

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name                  = "Title"
	titleLabel.Size                  = UDim2.new(1, -60, 0, 20)
	titleLabel.Position              = UDim2.fromOffset(44, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text                  = title
	titleLabel.TextColor3            = colors.Text
	titleLabel.TextSize              = fontSizes.Base or 13
	titleLabel.Font                  = fonts.Heading
	titleLabel.TextXAlignment        = Enum.TextXAlignment.Left
	titleLabel.TextTruncate          = Enum.TextTruncate.AtEnd
	titleLabel.ZIndex                = 502
	titleLabel.Parent                = frame

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name                  = "CloseBtn"
	closeBtn.Size                  = UDim2.fromOffset(20, 20)
	closeBtn.Position              = UDim2.new(1, -26, 0, 8)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Text                  = "×"
	closeBtn.TextColor3            = colors.TextMuted
	closeBtn.TextSize              = 18
	closeBtn.Font                  = fonts.Heading
	closeBtn.ZIndex                = 503
	closeBtn.Parent                = frame

	-- Message
	local msgLabel
	if message and #message > 0 then
		msgLabel = Instance.new("TextLabel")
		msgLabel.Name                  = "Message"
		msgLabel.Size                  = UDim2.new(1, -52, 0, 0)
		msgLabel.Position              = UDim2.fromOffset(44, 30)
		msgLabel.AutomaticSize         = Enum.AutomaticSize.Y
		msgLabel.BackgroundTransparency = 1
		msgLabel.Text                  = message
		msgLabel.TextColor3            = colors.TextSub
		msgLabel.TextSize              = fontSizes.Sm or 12
		msgLabel.Font                  = fonts.Body
		msgLabel.TextXAlignment        = Enum.TextXAlignment.Left
		msgLabel.TextWrapped           = true
		msgLabel.ZIndex                = 502
		msgLabel.Parent                = frame
	end

	-- Bottom padding frame
	local bottomPad = Instance.new("Frame")
	bottomPad.Name             = "BottomPad"
	bottomPad.Size             = UDim2.new(1, 0, 0, 8)
	bottomPad.BackgroundTransparency = 1
	bottomPad.ZIndex           = 501

	if msgLabel then
		bottomPad.Position = UDim2.new(0, 0, 0, 42 + (msgLabel.AbsoluteSize.Y or 0))
	else
		bottomPad.Position = UDim2.fromOffset(0, 38)
	end

	-- Progress bar
	local progressBg = Instance.new("Frame")
	progressBg.Name               = "ProgressBg"
	progressBg.Size               = UDim2.new(1, 0, 0, 2)
	progressBg.AnchorPoint        = Vector2.new(0, 1)
	progressBg.Position           = UDim2.new(0, 0, 1, 0)
	progressBg.BackgroundColor3   = colors.Surface3
	progressBg.BackgroundTransparency = 0
	progressBg.BorderSizePixel    = 0
	progressBg.ZIndex             = 502
	progressBg.Parent             = frame

	local progressBar = Instance.new("Frame")
	progressBar.Name              = "ProgressBar"
	progressBar.Size              = UDim2.fromScale(1, 1)
	progressBar.BackgroundColor3  = accentColor
	progressBar.BorderSizePixel   = 0
	progressBar.ZIndex            = 503
	progressBar.Parent            = progressBg

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 1)
	progressCorner.Parent = progressBg

	frame.Parent = self._stack

	-- Item data
	local item = {
		frame     = frame,
		dismissed = false,
		timer     = nil,
	}
	table.insert(self._items, item)

	-- Slide in animation
	TweenService:Create(frame, SLIDE_IN_INFO, {
		Position = UDim2.fromOffset(0, 0),
	}):Play()

	-- Progress bar animation
	if duration > 0 then
		TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
			Size = UDim2.fromOffset(0, progressBg.AbsoluteSize.Y),
		}):Play()
	end

	-- Click to dismiss
	local clickConn
	clickConn = frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:_dismissItem(item)
		end
	end)

	local closeBtnConn
	closeBtnConn = closeBtn.MouseButton1Click:Connect(function()
		self:_dismissItem(item)
	end)

	-- Auto-dismiss timer
	if duration > 0 then
		item.timer = task.delay(duration, function()
			self:_dismissItem(item)
		end)
	end

	-- Hover effect
	frame.MouseEnter:Connect(function()
		TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			BackgroundColor3 = colors.Surface3,
		}):Play()
	end)

	frame.MouseLeave:Connect(function()
		TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			BackgroundColor3 = colors.Surface2,
		}):Play()
	end)

	item._clickConn    = clickConn
	item._closeBtnConn = closeBtnConn

	return item
end

--- Dismiss a notification item with animation
---@param item table
function Notification:_dismissItem(item: table)
	if item.dismissed then return end
	item.dismissed = true

	if item.timer then
		task.cancel(item.timer)
		item.timer = nil
	end

	if item._clickConn then
		item._clickConn:Disconnect()
	end

	if item._closeBtnConn then
		item._closeBtnConn:Disconnect()
	end

	-- Remove from items list
	for i, v in ipairs(self._items) do
		if v == item then
			table.remove(self._items, i)
			break
		end
	end

	-- Slide out + fade
	local notifWidth = (self._theme.Components and self._theme.Components.Notification and self._theme.Components.Notification.Width) or 300

	TweenService:Create(item.frame, SLIDE_OUT_INFO, {
		Position = UDim2.fromOffset(notifWidth + 20, 0),
	}):Play()

	TweenService:Create(item.frame, SLIDE_OUT_INFO, {
		BackgroundTransparency = 1,
	}):Play()

	task.delay(0.30, function()
		if item.frame and item.frame.Parent then
			item.frame:Destroy()
		end
	end)
end

--- Dismiss all notifications
function Notification:DismissAll()
	local items = table.clone(self._items)
	for _, item in ipairs(items) do
		self:_dismissItem(item)
	end
end

--- Destroy the notification manager
function Notification:Destroy()
	self:DismissAll()
	if self._stack then
		self._stack:Destroy()
	end
end

return Notification
