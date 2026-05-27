-- libui/components/Window.lua
-- Main window component for LibUI

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local Window = {}
Window.__index = Window

local OPEN_INFO  = TweenInfo.new(0.35, Enum.EasingStyle.Quint,  Enum.EasingDirection.Out)
local CLOSE_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quart,  Enum.EasingDirection.In)
local HOVER_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quart,  Enum.EasingDirection.Out)

--- Create a shadow ImageLabel
local function createShadow(parent, shadowCfg, zIndex)
	local shadow = Instance.new("ImageLabel")
	shadow.Name                  = "Shadow"
	shadow.Size                  = shadowCfg.Size
	shadow.Position              = shadowCfg.Position
	shadow.BackgroundTransparency = 1
	shadow.Image                 = "rbxassetid://5554236805"
	shadow.ImageColor3           = shadowCfg.Color
	shadow.ImageTransparency     = shadowCfg.Transparency
	shadow.ScaleType             = Enum.ScaleType.Slice
	shadow.SliceCenter           = Rect.new(23, 23, 277, 277)
	shadow.ZIndex                = zIndex or 1
	shadow.Parent                = parent
	return shadow
end

--- Create a new Window
---@param screenGui ScreenGui
---@param options table { Title, Subtitle, Size, Position, MinSize, Resizable, Closable, Minimizable }
---@param theme table
---@return table Window object
function Window.new(screenGui: ScreenGui, options: table, theme: table)
	assert(screenGui, "Window.new: screenGui is nil")

	local colors    = theme.Colors
	local fonts     = theme.Fonts
	local fontSizes = theme.FontSizes
	local spacing   = theme.Spacing
	local radius    = theme.Radius
	local winCfg    = (theme.Components and theme.Components.Window) or {
		TitleBarHeight = 44, TabBarHeight = 36,
		DefaultWidth = 560, DefaultHeight = 420,
		MinWidth = 320, MinHeight = 240,
	}
	local shadows   = theme.Shadows

	local self           = setmetatable({}, Window)
	self._theme          = theme
	self._connections    = {}
	self._tabs           = {}
	self._destroyed      = false
	self._visible        = false
	self._onCloseCallbacks = {}
	self._activeTab      = nil

	local winW = options.Size and options.Size.X or winCfg.DefaultWidth
	local winH = options.Size and options.Size.Y or winCfg.DefaultHeight

	-- Shadow container (behind window)
	local shadowHolder = Instance.new("Frame")
	shadowHolder.Name                   = "ShadowHolder"
	shadowHolder.Size                   = UDim2.fromOffset(winW, winH)
	shadowHolder.Position               = options.Position
		or UDim2.new(0.5, -winW / 2, 0.5, -winH / 2)
	shadowHolder.BackgroundTransparency = 1
	shadowHolder.ZIndex                 = 10
	shadowHolder.Parent                 = screenGui

	createShadow(shadowHolder, shadows.Window, 10)

	-- Main window frame
	local win = Instance.new("Frame")
	win.Name                   = "Window"
	win.Size                   = UDim2.fromOffset(winW, winH)
	win.Position               = UDim2.fromScale(0, 0)
	win.BackgroundColor3       = colors.Surface
	win.BackgroundTransparency = theme.Transparency.WindowBG or 0.15
	win.BorderSizePixel        = 0
	win.ClipsDescendants       = true
	win.ZIndex                 = 11
	win.Parent                 = shadowHolder

	local winCorner = Instance.new("UICorner")
	winCorner.CornerRadius = UDim.new(0, radius.Window or 12)
	winCorner.Parent = win

	-- Outer border stroke
	local winStroke = Instance.new("UIStroke")
	winStroke.Color        = colors.Border
	winStroke.Transparency = theme.Transparency.Border or 0.07
	winStroke.Thickness    = 1
	winStroke.Parent       = win

	-- BG tint layer (subtle gradient overlay)
	local bgTint = Instance.new("Frame")
	bgTint.Name                   = "BgTint"
	bgTint.Size                   = UDim2.fromScale(1, 1)
	bgTint.BackgroundColor3       = colors.BG
	bgTint.BackgroundTransparency = 0.85
	bgTint.BorderSizePixel        = 0
	bgTint.ZIndex                 = win.ZIndex
	bgTint.Parent                 = win

	-- ============================================================
	-- Title Bar
	-- ============================================================
	local titleBarH = winCfg.TitleBarHeight
	local titleBar  = Instance.new("Frame")
	titleBar.Name             = "TitleBar"
	titleBar.Size             = UDim2.new(1, 0, 0, titleBarH)
	titleBar.BackgroundColor3 = colors.Surface2
	titleBar.BackgroundTransparency = 0.30
	titleBar.BorderSizePixel  = 0
	titleBar.ZIndex           = win.ZIndex + 1
	titleBar.Parent           = win

	-- Title bar bottom divider
	local titleDivider = Instance.new("Frame")
	titleDivider.Name             = "TitleDivider"
	titleDivider.Size             = UDim2.new(1, 0, 0, 1)
	titleDivider.Position         = UDim2.new(0, 0, 1, -1)
	titleDivider.BackgroundColor3 = colors.Border
	titleDivider.BackgroundTransparency = theme.Transparency.Border or 0.07
	titleDivider.BorderSizePixel  = 0
	titleDivider.ZIndex           = titleBar.ZIndex + 1
	titleDivider.Parent           = titleBar

	-- macOS-style control dots
	local dotY = titleBarH / 2 - 5
	local dots  = { { Color = colors.Danger, x = 14 }, { Color = colors.Warning, x = 34 }, { Color = colors.Success, x = 54 } }

	local closeBtn, minimizeBtn, maximizeBtn
	local controlBtns = {}

	for i, dot in ipairs(dots) do
		local dotFrame = Instance.new("TextButton")
		dotFrame.Name             = "ControlDot_" .. i
		dotFrame.Size             = UDim2.fromOffset(12, 12)
		dotFrame.Position         = UDim2.fromOffset(dot.x, dotY)
		dotFrame.BackgroundColor3 = dot.Color
		dotFrame.BorderSizePixel  = 0
		dotFrame.Text             = ""
		dotFrame.AutoButtonColor  = false
		dotFrame.ZIndex           = titleBar.ZIndex + 2
		dotFrame.Parent           = titleBar

		local dotCorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(1, 0)
		dotCorner.Parent = dotFrame

		-- Hover shows symbol
		local symbol = Instance.new("TextLabel")
		symbol.Name                  = "Symbol"
		symbol.Size                  = UDim2.fromScale(1, 1)
		symbol.BackgroundTransparency = 1
		symbol.Text                  = i == 1 and "×" or (i == 2 and "−" or "+")
		symbol.TextColor3            = Color3.fromRGB(0, 0, 0)
		symbol.TextTransparency      = 1
		symbol.TextSize              = 9
		symbol.Font                  = fonts.Heading
		symbol.ZIndex                = dotFrame.ZIndex + 1
		symbol.Parent                = dotFrame

		dotFrame.MouseEnter:Connect(function()
			TweenService:Create(dotFrame, HOVER_INFO, {
				BackgroundColor3 = Color3.new(
					math.min(dot.Color.R * 1.1, 1),
					math.min(dot.Color.G * 1.1, 1),
					math.min(dot.Color.B * 1.1, 1)
				),
			}):Play()
			TweenService:Create(symbol, HOVER_INFO, { TextTransparency = 0.3 }):Play()
		end)

		dotFrame.MouseLeave:Connect(function()
			TweenService:Create(dotFrame, HOVER_INFO, { BackgroundColor3 = dot.Color }):Play()
			TweenService:Create(symbol, HOVER_INFO, { TextTransparency = 1 }):Play()
		end)

		table.insert(controlBtns, dotFrame)
		if i == 1 then closeBtn = dotFrame end
		if i == 2 then minimizeBtn = dotFrame end
	end

	-- Title text
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name                  = "Title"
	titleLabel.Size                  = UDim2.new(1, -160, 1, 0)
	titleLabel.Position              = UDim2.fromOffset(winW / 2 - 80, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text                  = options.Title or "Window"
	titleLabel.TextColor3            = colors.Text
	titleLabel.TextSize              = fontSizes.Md or 14
	titleLabel.Font                  = fonts.Heading
	titleLabel.ZIndex                = titleBar.ZIndex + 1
	titleLabel.Parent                = titleBar

	-- Subtitle
	if options.Subtitle and #options.Subtitle > 0 then
		local subtitle = Instance.new("TextLabel")
		subtitle.Name                  = "Subtitle"
		subtitle.Size                  = UDim2.new(1, -160, 0, 14)
		subtitle.Position              = UDim2.fromOffset(winW / 2 - 80, 26)
		subtitle.BackgroundTransparency = 1
		subtitle.Text                  = options.Subtitle
		subtitle.TextColor3            = colors.TextMuted
		subtitle.TextSize              = fontSizes.Xs or 10
		subtitle.Font                  = fonts.Caption
		subtitle.ZIndex                = titleBar.ZIndex + 1
		subtitle.Parent                = titleBar
		self._subtitle = subtitle
	end

	-- ============================================================
	-- Tab Bar
	-- ============================================================
	local tabBarH = winCfg.TabBarHeight
	local tabBar  = Instance.new("Frame")
	tabBar.Name             = "TabBar"
	tabBar.Size             = UDim2.new(1, 0, 0, tabBarH)
	tabBar.Position         = UDim2.fromOffset(0, titleBarH)
	tabBar.BackgroundColor3 = colors.Surface
	tabBar.BackgroundTransparency = 0.20
	tabBar.BorderSizePixel  = 0
	tabBar.ClipsDescendants = true
	tabBar.ZIndex           = win.ZIndex + 1
	tabBar.Parent           = win

	local tabBarDivider = Instance.new("Frame")
	tabBarDivider.Name             = "TabBarDivider"
	tabBarDivider.Size             = UDim2.new(1, 0, 0, 1)
	tabBarDivider.Position         = UDim2.new(0, 0, 1, -1)
	tabBarDivider.BackgroundColor3 = colors.Border
	tabBarDivider.BackgroundTransparency = theme.Transparency.Border or 0.07
	tabBarDivider.BorderSizePixel  = 0
	tabBarDivider.ZIndex           = tabBar.ZIndex + 1
	tabBarDivider.Parent           = tabBar

	local tabBarLayout = Instance.new("UIListLayout")
	tabBarLayout.FillDirection       = Enum.FillDirection.Horizontal
	tabBarLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
	tabBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	tabBarLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	tabBarLayout.Padding             = UDim.new(0, 0)
	tabBarLayout.Parent              = tabBar

	local tabBarPad = Instance.new("UIPadding")
	tabBarPad.PaddingLeft = UDim.new(0, spacing.Sm or 8)
	tabBarPad.Parent      = tabBar

	-- ============================================================
	-- Content Area
	-- ============================================================
	local contentY = titleBarH + tabBarH
	local contentH = winH - contentY

	local contentArea = Instance.new("Frame")
	contentArea.Name             = "ContentArea"
	contentArea.Size             = UDim2.new(1, 0, 0, contentH)
	contentArea.Position         = UDim2.fromOffset(0, contentY)
	contentArea.BackgroundTransparency = 1
	contentArea.BorderSizePixel  = 0
	contentArea.ClipsDescendants = true
	contentArea.ZIndex           = win.ZIndex + 1
	contentArea.Parent           = win

	self._shadowHolder = shadowHolder
	self._win          = win
	self._titleLabel   = titleLabel
	self._titleBar     = titleBar
	self._tabBar       = tabBar
	self._contentArea  = contentArea
	self._closeBtn     = closeBtn
	self._minimizeBtn  = minimizeBtn
	self._winW         = winW
	self._winH         = winH
	self._screenGui    = screenGui
	self._minimized    = false

	-- ============================================================
	-- Close & Minimize actions
	-- ============================================================
	local closeConn = closeBtn.MouseButton1Click:Connect(function()
		for _, cb in ipairs(self._onCloseCallbacks) do
			task.spawn(cb)
		end
		self:Hide()
	end)

	local minimizeConn = minimizeBtn.MouseButton1Click:Connect(function()
		self:_toggleMinimize()
	end)

	table.insert(self._connections, closeConn)
	table.insert(self._connections, minimizeConn)

	-- ============================================================
	-- Dragging
	-- ============================================================
	local dragging     = false
	local dragStart    = Vector2.new()
	local startPos     = UDim2.new()

	local dragBeginConn = titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging  = true
			dragStart = Vector2.new(input.Position.X, input.Position.Y)
			startPos  = shadowHolder.Position
		end
	end)

	local dragChangeConn = UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
			shadowHolder.Position = UDim2.fromOffset(
				startPos.X.Offset + delta.X,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	local dragEndConn = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	table.insert(self._connections, dragBeginConn)
	table.insert(self._connections, dragChangeConn)
	table.insert(self._connections, dragEndConn)

	-- Start hidden
	shadowHolder.Visible = false

	return self
end

--- Toggle minimize
function Window:_toggleMinimize()
	self._minimized = not self._minimized
	local colors = self._theme.Colors

	if self._minimized then
		-- Collapse to title bar only
		local targetH = self._theme.Components.Window.TitleBarHeight + self._theme.Components.Window.TabBarHeight
		TweenService:Create(self._win, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(self._winW, targetH),
		}):Play()
		TweenService:Create(self._shadowHolder, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(self._winW, targetH),
		}):Play()
		self._contentArea.Visible = false
	else
		self._contentArea.Visible = true
		TweenService:Create(self._win, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(self._winW, self._winH),
		}):Play()
		TweenService:Create(self._shadowHolder, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(self._winW, self._winH),
		}):Play()
	end
end

--- Add a tab to the window
---@param opts table { Label, Icon }
---@return table Tab object
function Window:AddTab(opts: table)
	local Tab = require(script.Parent.Tab)
	local tab = Tab.new(self._tabBar, self._contentArea, opts, self._theme)
	table.insert(self._tabs, tab)

	-- Auto-select first tab
	if #self._tabs == 1 then
		task.defer(function()
			tab:Select()
			self._activeTab = tab
		end)
	end

	-- Track tab selection
	local origSelect = tab.Select
	tab.Select = function(t)
		-- Deactivate all other tabs
		for _, other in ipairs(self._tabs) do
			if other ~= t and other._active then
				other:_deactivate()
			end
		end
		self._activeTab = t
		origSelect(t)
	end

	return tab
end

--- Set window title
---@param text string
function Window:SetTitle(text: string)
	self._titleLabel.Text = text
end

--- Show the window with animation
function Window:Show()
	if self._visible then return end
	self._visible = true

	local win = self._win
	local holder = self._shadowHolder

	holder.Visible = true
	win.Size       = UDim2.fromOffset(self._winW * 0.95, self._winH * 0.95)
	win.BackgroundTransparency = 1

	TweenService:Create(win, OPEN_INFO, {
		Size               = UDim2.fromOffset(self._winW, self._winH),
		BackgroundTransparency = self._theme.Transparency.WindowBG or 0.15,
	}):Play()
end

--- Hide the window with animation
function Window:Hide()
	if not self._visible then return end
	self._visible = false

	local win = self._win
	local holder = self._shadowHolder

	TweenService:Create(win, CLOSE_INFO, {
		Size               = UDim2.fromOffset(self._winW * 0.95, self._winH * 0.95),
		BackgroundTransparency = 1,
	}):Play()

	task.delay(0.27, function()
		holder.Visible = false
		win.Size       = UDim2.fromOffset(self._winW, self._winH)
		win.BackgroundTransparency = self._theme.Transparency.WindowBG or 0.15
	end)
end

--- Register a close callback
---@param callback function
function Window:OnClose(callback: () -> ())
	table.insert(self._onCloseCallbacks, callback)
end

--- Destroy the window and all its contents
function Window:Destroy()
	if self._destroyed then return end
	self._destroyed = true

	for _, tab in ipairs(self._tabs) do
		if tab and tab.Destroy then tab:Destroy() end
	end
	table.clear(self._tabs)

	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)

	if self._shadowHolder then
		self._shadowHolder:Destroy()
	end
end

return Window
