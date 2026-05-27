-- libui/components/Tab.lua
-- Tab component for LibUI

local TweenService = game:GetService("TweenService")

local Tab = {}
Tab.__index = Tab

local INDICATOR_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local CONTENT_INFO   = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local HOVER_INFO     = TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

--- Create a new tab
---@param tabBar Frame The tab bar container
---@param contentArea Frame The content area where tab content will be placed
---@param options table { Label, Icon }
---@param theme table
---@return table Tab object
function Tab.new(tabBar: Frame, contentArea: Frame, options: table, theme: table)
	assert(tabBar,      "Tab.new: tabBar is nil")
	assert(contentArea, "Tab.new: contentArea is nil")

	local colors    = theme.Colors
	local fonts     = theme.Fonts
	local fontSizes = theme.FontSizes
	local radius    = theme.Radius
	local tabCfg    = (theme.Components and theme.Components.Tab) or
		{ IndicatorHeight = 2, PaddingH = 16 }

	local self        = setmetatable({}, Tab)
	self._theme       = theme
	self._connections = {}
	self._destroyed   = false
	self._active      = false
	self._sections    = {}
	self._tabBar      = tabBar
	self._contentArea = contentArea

	-- Measure text for tab button width
	local textService = game:GetService("TextService")
	local labelText   = options.Label or "Tab"
	local textSize    = textService:GetTextSize(
		labelText,
		fontSizes.Base or 13,
		fonts.SemiBold or fonts.Heading,
		Vector2.new(200, 30)
	)
	local tabW = textSize.X + tabCfg.PaddingH * 2

	if options.Icon then
		tabW = tabW + 20
	end

	-- Tab button in tab bar
	local tabBtn = Instance.new("TextButton")
	tabBtn.Name                   = "Tab_" .. labelText
	tabBtn.Size                   = UDim2.fromOffset(tabW, tabBar.AbsoluteSize.Y > 0 and tabBar.AbsoluteSize.Y or 36)
	tabBtn.BackgroundTransparency = 1
	tabBtn.Text                   = ""
	tabBtn.AutoButtonColor        = false
	tabBtn.ZIndex                 = tabBar.ZIndex + 1
	tabBtn.Parent                 = tabBar

	-- Layout inside tab button
	local tabContent = Instance.new("Frame")
	tabContent.Name                   = "TabContent"
	tabContent.Size                   = UDim2.fromScale(1, 1)
	tabContent.BackgroundTransparency = 1
	tabContent.ZIndex                 = tabBtn.ZIndex + 1
	tabContent.Parent                 = tabBtn

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection       = Enum.FillDirection.Horizontal
	tabLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabLayout.Padding             = UDim.new(0, 6)
	tabLayout.Parent              = tabContent

	-- Optional icon
	if options.Icon and #options.Icon > 0 then
		local icon = Instance.new("ImageLabel")
		icon.Name                  = "Icon"
		icon.Size                  = UDim2.fromOffset(14, 14)
		icon.BackgroundTransparency = 1
		icon.Image                 = options.Icon
		icon.ImageColor3           = colors.TextSub
		icon.ZIndex                = tabContent.ZIndex + 1
		icon.Parent                = tabContent
		self._icon = icon
	end

	-- Label
	local label = Instance.new("TextLabel")
	label.Name                  = "Label"
	label.Size                  = UDim2.fromOffset(textSize.X, 20)
	label.BackgroundTransparency = 1
	label.Text                  = labelText
	label.TextColor3            = colors.TextSub
	label.TextSize              = fontSizes.Base or 13
	label.Font                  = fonts.SemiBold or fonts.Heading
	label.ZIndex                = tabContent.ZIndex + 1
	label.Parent                = tabContent

	-- Active indicator (underline)
	local indicator = Instance.new("Frame")
	indicator.Name             = "Indicator"
	indicator.Size             = UDim2.fromOffset(0, tabCfg.IndicatorHeight)
	indicator.Position         = UDim2.new(0.5, 0, 1, -tabCfg.IndicatorHeight)
	indicator.AnchorPoint      = Vector2.new(0.5, 0)
	indicator.BackgroundColor3 = colors.Accent
	indicator.BorderSizePixel  = 0
	indicator.ZIndex           = tabBtn.ZIndex + 2
	indicator.Parent           = tabBtn

	local indCorner = Instance.new("UICorner")
	indCorner.CornerRadius = UDim.new(1, 0)
	indCorner.Parent = indicator

	-- Content frame (placed in contentArea, hidden by default)
	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name                 = "TabContent_" .. labelText
	contentFrame.Size                 = UDim2.fromScale(1, 1)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel      = 0
	contentFrame.ScrollBarThickness   = 3
	contentFrame.ScrollBarImageColor3 = colors.Accent
	contentFrame.CanvasSize           = UDim2.fromOffset(0, 0)
	contentFrame.AutomaticCanvasSize  = Enum.AutomaticSize.Y
	contentFrame.Visible              = false
	contentFrame.ZIndex               = contentArea.ZIndex + 1
	contentFrame.Parent               = contentArea

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.FillDirection       = Enum.FillDirection.Vertical
	contentLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	contentLayout.Padding             = UDim.new(0, 8)
	contentLayout.Parent              = contentFrame

	local contentPad = Instance.new("UIPadding")
	contentPad.PaddingLeft   = UDim.new(0, 12)
	contentPad.PaddingRight  = UDim.new(0, 12)
	contentPad.PaddingTop    = UDim.new(0, 10)
	contentPad.PaddingBottom = UDim.new(0, 10)
	contentPad.Parent        = contentFrame

	self._tabBtn       = tabBtn
	self._label        = label
	self._indicator    = indicator
	self._contentFrame = contentFrame

	-- Hover effect
	local hoverConn = tabBtn.MouseEnter:Connect(function()
		if not self._active then
			TweenService:Create(label, HOVER_INFO, { TextColor3 = colors.Text }):Play()
			if self._icon then
				TweenService:Create(self._icon, HOVER_INFO, { ImageColor3 = colors.Text }):Play()
			end
		end
	end)

	local leaveConn = tabBtn.MouseLeave:Connect(function()
		if not self._active then
			TweenService:Create(label, HOVER_INFO, { TextColor3 = colors.TextSub }):Play()
			if self._icon then
				TweenService:Create(self._icon, HOVER_INFO, { ImageColor3 = colors.TextSub }):Play()
			end
		end
	end)

	-- Click to select
	local clickConn = tabBtn.MouseButton1Click:Connect(function()
		self:Select()
	end)

	table.insert(self._connections, hoverConn)
	table.insert(self._connections, leaveConn)
	table.insert(self._connections, clickConn)

	return self
end

--- Select/activate this tab
function Tab:Select()
	if self._active then return end

	-- Deactivate all sibling tabs
	for _, sibling in ipairs(self._tabBar:GetChildren()) do
		if sibling:IsA("TextButton") and sibling ~= self._tabBtn then
			local sibLabel = sibling:FindFirstChild("TabContent") and sibling:FindFirstChild("TabContent"):FindFirstChild("Label")
			local sibIndicator = sibling:FindFirstChild("Indicator")
			local sibIcon = sibling:FindFirstChild("TabContent") and sibling:FindFirstChild("TabContent"):FindFirstChild("Icon")

			if sibLabel then
				TweenService:Create(sibLabel, INDICATOR_INFO, { TextColor3 = self._theme.Colors.TextSub }):Play()
			end
			if sibIndicator then
				TweenService:Create(sibIndicator, INDICATOR_INFO, { Size = UDim2.fromOffset(0, sibIndicator.Size.Y.Offset) }):Play()
			end
			if sibIcon then
				TweenService:Create(sibIcon, INDICATOR_INFO, { ImageColor3 = self._theme.Colors.TextSub }):Play()
			end
			sibling:SetAttribute("Active", false)
		end
	end

	-- Hide all content frames in parent
	for _, child in ipairs(self._contentArea:GetChildren()) do
		if child:IsA("ScrollingFrame") and child ~= self._contentFrame then
			child.Visible = false
		end
	end

	-- Activate this tab
	self._active = true
	self._tabBtn:SetAttribute("Active", true)

	TweenService:Create(self._label, INDICATOR_INFO, { TextColor3 = self._theme.Colors.Text }):Play()
	if self._icon then
		TweenService:Create(self._icon, INDICATOR_INFO, { ImageColor3 = self._theme.Colors.Accent }):Play()
	end

	-- Expand indicator
	TweenService:Create(self._indicator, INDICATOR_INFO, {
		Size = UDim2.fromOffset(self._tabBtn.AbsoluteSize.X - 16, self._indicator.Size.Y.Offset),
	}):Play()

	-- Show content with fade-in
	self._contentFrame.Visible = true
	self._contentFrame.Position = UDim2.fromOffset(0, 4)

	TweenService:Create(self._contentFrame, CONTENT_INFO, { Position = UDim2.fromOffset(0, 0) }):Play()

	-- Reset active on deselect tracking
	task.spawn(function()
		-- Mark siblings as inactive
		for _, sibling in ipairs(self._tabBar:GetChildren()) do
			if sibling:IsA("TextButton") and sibling ~= self._tabBtn then
				sibling:SetAttribute("Active", false)
				-- find associated tab object to update _active
			end
		end
	end)
end

--- Deactivate this tab (called by another tab's Select)
function Tab:_deactivate()
	self._active = false
	local colors = self._theme.Colors

	TweenService:Create(self._label, INDICATOR_INFO, { TextColor3 = colors.TextSub }):Play()
	TweenService:Create(self._indicator, INDICATOR_INFO, {
		Size = UDim2.fromOffset(0, self._indicator.Size.Y.Offset),
	}):Play()

	if self._icon then
		TweenService:Create(self._icon, INDICATOR_INFO, { ImageColor3 = colors.TextSub }):Play()
	end

	self._contentFrame.Visible = false
end

--- Add a section to this tab's content
---@param opts table { Title, Description, Collapsible }
---@return table Section object
function Tab:AddSection(opts: table)
	local Section = (rawget(_G,'_SolarisReg') and _G._SolarisReg['components/Section']) or require(script.Parent.Section)
	local section = Section.new(self._contentFrame, opts, self._theme)
	table.insert(self._sections, section)
	return section
end

--- Destroy the tab
function Tab:Destroy()
	if self._destroyed then return end
	self._destroyed = true

	for _, section in ipairs(self._sections) do
		if section and section.Destroy then
			section:Destroy()
		end
	end
	table.clear(self._sections)

	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)

	if self._tabBtn then self._tabBtn:Destroy() end
	if self._contentFrame then self._contentFrame:Destroy() end
end

return Tab
