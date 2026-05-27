-- libui/components/Section.lua
-- Section/group container component for LibUI

local TweenService = game:GetService("TweenService")

local Section = {}
Section.__index = Section

local COLLAPSE_INFO = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local HOVER_INFO    = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

--- Create a new section component
---@param parent GuiObject
---@param options table { Title, Description, Collapsible }
---@param theme table
---@return table Section object
function Section.new(parent: GuiObject, options: table, theme: table)
	assert(parent, "Section.new: parent is nil")

	local colors    = theme.Colors
	local fonts     = theme.Fonts
	local fontSizes = theme.FontSizes
	local spacing   = theme.Spacing
	local radius    = theme.Radius

	local self         = setmetatable({}, Section)
	self._theme        = theme
	self._connections  = {}
	self._destroyed    = false
	self._collapsed    = false
	self._collapsible  = options.Collapsible == true
	self._elements     = {}

	-- Outer container (auto-sizes)
	local container = Instance.new("Frame")
	container.Name             = "SectionContainer"
	container.Size             = UDim2.new(1, 0, 0, 0)
	container.AutomaticSize    = Enum.AutomaticSize.Y
	container.BackgroundColor3 = colors.Surface
	container.BackgroundTransparency = 0
	container.BorderSizePixel  = 0
	container.Parent           = parent

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, radius.Card or 8)
	containerCorner.Parent = container

	local containerStroke = Instance.new("UIStroke")
	containerStroke.Color        = colors.Border
	containerStroke.Transparency = theme.Transparency.Border or 0.07
	containerStroke.Thickness    = 1
	containerStroke.Parent = container

	-- Header
	local headerH = options.Description and #(options.Description or "") > 0 and 48 or 38

	local header = Instance.new("Frame")
	header.Name             = "Header"
	header.Size             = UDim2.new(1, 0, 0, headerH)
	header.BackgroundTransparency = 1
	header.BorderSizePixel  = 0
	header.ZIndex           = container.ZIndex + 1
	header.Parent           = container

	-- Title
	local title = Instance.new("TextLabel")
	title.Name                  = "Title"
	title.Size                  = UDim2.new(1, -40, 0, 18)
	title.Position              = UDim2.fromOffset(spacing.Md or 12, options.Description and #(options.Description or "") > 0 and 8 or (headerH - 18) / 2)
	title.BackgroundTransparency = 1
	title.Text                  = options.Title or "Section"
	title.TextColor3            = colors.Text
	title.TextSize              = fontSizes.Md or 14
	title.Font                  = fonts.Heading
	title.TextXAlignment        = Enum.TextXAlignment.Left
	title.ZIndex                = header.ZIndex + 1
	title.Parent                = header

	if options.Description and #options.Description > 0 then
		local desc = Instance.new("TextLabel")
		desc.Name                   = "Description"
		desc.Size                   = UDim2.new(1, -40, 0, 14)
		desc.Position               = UDim2.fromOffset(spacing.Md or 12, 27)
		desc.BackgroundTransparency = 1
		desc.Text                   = options.Description
		desc.TextColor3             = colors.TextMuted
		desc.TextSize               = fontSizes.Xs or 10
		desc.Font                   = fonts.Caption
		desc.TextXAlignment         = Enum.TextXAlignment.Left
		desc.ZIndex                 = header.ZIndex + 1
		desc.Parent                 = header
	end

	-- Collapse arrow
	local arrow = nil
	if self._collapsible then
		arrow = Instance.new("TextLabel")
		arrow.Name                  = "Arrow"
		arrow.Size                  = UDim2.fromOffset(20, 20)
		arrow.Position              = UDim2.new(1, -28, 0.5, -10)
		arrow.BackgroundTransparency = 1
		arrow.Text                  = "▾"
		arrow.TextColor3            = colors.TextMuted
		arrow.TextSize              = 14
		arrow.Font                  = fonts.Body
		arrow.ZIndex                = header.ZIndex + 1
		arrow.Parent                = header
		self._arrow = arrow

		-- Hover header
		local headerBtn = Instance.new("TextButton")
		headerBtn.Name                   = "HeaderBtn"
		headerBtn.Size                   = UDim2.fromScale(1, 1)
		headerBtn.BackgroundTransparency = 1
		headerBtn.Text                   = ""
		headerBtn.ZIndex                 = header.ZIndex + 2
		headerBtn.Parent                 = header

		local headerHoverConn = headerBtn.MouseEnter:Connect(function()
			TweenService:Create(header, HOVER_INFO, { BackgroundTransparency = 0.96 }):Play()
		end)

		local headerLeaveConn = headerBtn.MouseLeave:Connect(function()
			TweenService:Create(header, HOVER_INFO, { BackgroundTransparency = 1 }):Play()
		end)

		local headerClickConn = headerBtn.MouseButton1Click:Connect(function()
			self:_toggleCollapse()
		end)

		table.insert(self._connections, headerHoverConn)
		table.insert(self._connections, headerLeaveConn)
		table.insert(self._connections, headerClickConn)
	end

	-- Divider line
	local divider = Instance.new("Frame")
	divider.Name             = "Divider"
	divider.Size             = UDim2.new(1, -24, 0, 1)
	divider.Position         = UDim2.fromOffset(12, headerH)
	divider.BackgroundColor3 = colors.Border
	divider.BackgroundTransparency = theme.Transparency.Border or 0.07
	divider.BorderSizePixel  = 0
	divider.ZIndex           = container.ZIndex + 1
	divider.Parent           = container

	-- Content area
	local content = Instance.new("Frame")
	content.Name             = "Content"
	content.Size             = UDim2.new(1, 0, 0, 0)
	content.Position         = UDim2.fromOffset(0, headerH + 1)
	content.BackgroundTransparency = 1
	content.BorderSizePixel  = 0
	content.AutomaticSize    = Enum.AutomaticSize.Y
	content.ClipsDescendants = true
	content.ZIndex           = container.ZIndex + 1
	content.Parent           = container

	-- Layout for content items
	local contentLayout = Instance.new("UIListLayout")
	contentLayout.FillDirection       = Enum.FillDirection.Vertical
	contentLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	contentLayout.Padding             = UDim.new(0, 0)
	contentLayout.Parent              = content

	local contentPad = Instance.new("UIPadding")
	contentPad.PaddingLeft   = UDim.new(0, spacing.Md or 12)
	contentPad.PaddingRight  = UDim.new(0, spacing.Md or 12)
	contentPad.PaddingTop    = UDim.new(0, spacing.Sm or 8)
	contentPad.PaddingBottom = UDim.new(0, spacing.Sm or 8)
	contentPad.Parent        = content

	self._container = container
	self._header    = header
	self._content   = content
	self._title     = title
	self._divider   = divider

	return self
end

--- Toggle collapsed state
function Section:_toggleCollapse()
	self._collapsed = not self._collapsed
	local colors = self._theme.Colors

	if self._collapsed then
		TweenService:Create(self._arrow, COLLAPSE_INFO, { Rotation = -90 }):Play()
		-- Hide content by setting size
		self._content.Visible = false
		self._divider.Visible = false
	else
		TweenService:Create(self._arrow, COLLAPSE_INFO, { Rotation = 0 }):Play()
		self._content.Visible = true
		self._divider.Visible = true
	end
end

--- Add an element frame directly to the section
---@param element GuiObject
function Section:AddElement(element: GuiObject)
	element.Parent = self._content
	table.insert(self._elements, element)
	return element
end

--- Set section title
---@param text string
function Section:SetTitle(text: string)
	self._title.Text = text
end

--- Convenience: Add a Toggle
---@param opts table
---@return table Toggle object
function Section:AddToggle(opts: table)
	local Toggle = (rawget(_G,'_SolarisReg') and _G._SolarisReg['components/Toggle']) or require(script.Parent.Toggle)
	local toggle = Toggle.new(self._content, opts, self._theme)
	table.insert(self._elements, toggle)
	return toggle
end

--- Convenience: Add a Slider
---@param opts table
---@return table Slider object
function Section:AddSlider(opts: table)
	local Slider = (rawget(_G,'_SolarisReg') and _G._SolarisReg['components/Slider']) or require(script.Parent.Slider)
	local slider = Slider.new(self._content, opts, self._theme)
	table.insert(self._elements, slider)
	return slider
end

--- Convenience: Add a Button
---@param opts table
---@return table Button object
function Section:AddButton(opts: table)
	local Button = (rawget(_G,'_SolarisReg') and _G._SolarisReg['components/Button']) or require(script.Parent.Button)
	local button = Button.new(self._content, opts, self._theme)
	table.insert(self._elements, button)
	return button
end

--- Convenience: Add a Dropdown
---@param opts table
---@return table Dropdown object
function Section:AddDropdown(opts: table)
	local Dropdown = (rawget(_G,'_SolarisReg') and _G._SolarisReg['components/Dropdown']) or require(script.Parent.Dropdown)
	local dropdown = Dropdown.new(self._content, opts, self._theme)
	table.insert(self._elements, dropdown)
	return dropdown
end

--- Convenience: Add a TextBox
---@param opts table
---@return table TextBox object
function Section:AddTextBox(opts: table)
	local TextBox = (rawget(_G,'_SolarisReg') and _G._SolarisReg['components/TextBox']) or require(script.Parent.TextBox)
	local textbox = TextBox.new(self._content, opts, self._theme)
	table.insert(self._elements, textbox)
	return textbox
end

--- Convenience: Add a ColorPicker
---@param opts table
---@return table ColorPicker object
function Section:AddColorPicker(opts: table)
	local ColorPicker = (rawget(_G,'_SolarisReg') and _G._SolarisReg['components/ColorPicker']) or require(script.Parent.ColorPicker)
	local picker = ColorPicker.new(self._content, opts, self._theme)
	table.insert(self._elements, picker)
	return picker
end

--- Convenience: Add a Keybind
---@param opts table
---@return table Keybind object
function Section:AddKeybind(opts: table)
	local Keybind = (rawget(_G,'_SolarisReg') and _G._SolarisReg['components/Keybind']) or require(script.Parent.Keybind)
	local keybind = Keybind.new(self._content, opts, self._theme)
	table.insert(self._elements, keybind)
	return keybind
end

--- Destroy the section and all its elements
function Section:Destroy()
	if self._destroyed then return end
	self._destroyed = true

	-- Destroy child elements
	for _, elem in ipairs(self._elements) do
		if type(elem) == "table" and elem.Destroy then
			elem:Destroy()
		end
	end
	table.clear(self._elements)

	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)

	if self._container then
		self._container:Destroy()
	end
end

return Section
