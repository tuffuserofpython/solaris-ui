-- libui/components/Dropdown.lua
-- Single-select dropdown component for LibUI

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Dropdown = {}
Dropdown.__index = Dropdown

local OPEN_INFO  = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local CLOSE_INFO = TweenInfo.new(0.20, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
local HOVER_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

--- Create a new dropdown component
---@param parent GuiObject
---@param options table { Label, Description, Items, Default, Callback }
---@param theme table
---@return table Dropdown object
function Dropdown.new(parent: GuiObject, options: table, theme: table)
	assert(parent, "Dropdown.new: parent is nil")

	local colors    = theme.Colors
	local fonts     = theme.Fonts
	local fontSizes = theme.FontSizes
	local spacing   = theme.Spacing
	local radius    = theme.Radius
	local ddCfg     = (theme.Components and theme.Components.Dropdown) or
		{ Height = 36, ItemHeight = 32, MaxVisible = 5 }

	local self        = setmetatable({}, Dropdown)
	self._theme       = theme
	self._connections = {}
	self._items       = options.Items or {}
	self._value       = options.Default
	self._callback    = options.Callback
	self._destroyed   = false
	self._open        = false

	local hasDesc = options.Description and #options.Description > 0
	local rowH    = hasDesc and 68 or 52

	-- Row container
	local row = Instance.new("Frame")
	row.Name                   = "DropdownRow"
	row.Size                   = UDim2.new(1, 0, 0, rowH)
	row.BackgroundTransparency = 1
	row.BorderSizePixel        = 0
	row.ClipsDescendants       = false
	row.Parent                 = parent

	local labelY  = 6
	local dropY   = hasDesc and 44 or 30

	-- Label
	local label = Instance.new("TextLabel")
	label.Name                  = "Label"
	label.Size                  = UDim2.new(1, -16, 0, 18)
	label.Position              = UDim2.fromOffset(8, labelY)
	label.BackgroundTransparency = 1
	label.Text                  = options.Label or "Dropdown"
	label.TextColor3            = colors.Text
	label.TextSize              = fontSizes.Base or 13
	label.Font                  = fonts.Body
	label.TextXAlignment        = Enum.TextXAlignment.Left
	label.Parent                = row

	if hasDesc then
		local desc = Instance.new("TextLabel")
		desc.Name                   = "Description"
		desc.Size                   = UDim2.new(1, -16, 0, 13)
		desc.Position               = UDim2.fromOffset(8, labelY + 19)
		desc.BackgroundTransparency = 1
		desc.Text                   = options.Description
		desc.TextColor3             = colors.TextMuted
		desc.TextSize               = fontSizes.Xs or 10
		desc.Font                   = fonts.Caption
		desc.TextXAlignment         = Enum.TextXAlignment.Left
		desc.Parent                 = row
	end

	-- Dropdown button
	local dropBtn = Instance.new("TextButton")
	dropBtn.Name                   = "DropBtn"
	dropBtn.Size                   = UDim2.new(1, -16, 0, ddCfg.Height)
	dropBtn.Position               = UDim2.fromOffset(8, dropY)
	dropBtn.BackgroundColor3       = colors.Surface2
	dropBtn.BorderSizePixel        = 0
	dropBtn.Text                   = ""
	dropBtn.AutoButtonColor        = false
	dropBtn.ZIndex                 = row.ZIndex + 1
	dropBtn.Parent                 = row

	local dropCorner = Instance.new("UICorner")
	dropCorner.CornerRadius = UDim.new(0, radius.Button or 6)
	dropCorner.Parent = dropBtn

	local dropStroke = Instance.new("UIStroke")
	dropStroke.Color        = colors.Border
	dropStroke.Transparency = theme.Transparency.Border or 0.07
	dropStroke.Thickness    = 1
	dropStroke.Parent       = dropBtn

	-- Selected text
	local selectedLabel = Instance.new("TextLabel")
	selectedLabel.Name                  = "SelectedLabel"
	selectedLabel.Size                  = UDim2.new(1, -36, 1, 0)
	selectedLabel.Position              = UDim2.fromOffset(12, 0)
	selectedLabel.BackgroundTransparency = 1
	selectedLabel.Text                  = self._value or "Select..."
	selectedLabel.TextColor3            = self._value and colors.Text or colors.TextMuted
	selectedLabel.TextSize              = fontSizes.Base or 13
	selectedLabel.Font                  = fonts.Body
	selectedLabel.TextXAlignment        = Enum.TextXAlignment.Left
	selectedLabel.TextTruncate          = Enum.TextTruncate.AtEnd
	selectedLabel.ZIndex                = dropBtn.ZIndex + 1
	selectedLabel.Parent                = dropBtn

	-- Chevron arrow
	local chevron = Instance.new("TextLabel")
	chevron.Name                  = "Chevron"
	chevron.Size                  = UDim2.fromOffset(20, 20)
	chevron.Position              = UDim2.new(1, -26, 0.5, -10)
	chevron.BackgroundTransparency = 1
	chevron.Text                  = "▾"
	chevron.TextColor3            = colors.TextMuted
	chevron.TextSize              = 14
	chevron.Font                  = fonts.Body
	chevron.ZIndex                = dropBtn.ZIndex + 1
	chevron.Parent                = dropBtn

	-- Dropdown panel (created dynamically, lives in a higher-ZIndex layer)
	local dropPanel = nil

	self._row           = row
	self._dropBtn       = dropBtn
	self._selectedLabel = selectedLabel
	self._chevron       = chevron
	self._dropStroke    = dropStroke
	self._dropPanel     = nil
	self._ddCfg         = ddCfg

	local function closeDropdown()
		if not self._open then return end
		self._open = false

		if dropPanel then
			TweenService:Create(dropPanel, CLOSE_INFO, {
				Size = UDim2.new(dropPanel.Size.X.Scale, dropPanel.Size.X.Offset, 0, 0),
			}):Play()
			TweenService:Create(dropPanel, CLOSE_INFO, { BackgroundTransparency = 1 }):Play()
			task.delay(0.22, function()
				if dropPanel then
					dropPanel:Destroy()
					dropPanel = nil
					self._dropPanel = nil
				end
			end)
		end

		TweenService:Create(chevron, HOVER_INFO, { Rotation = 0 }):Play()
		TweenService:Create(dropBtn, HOVER_INFO, { BackgroundColor3 = colors.Surface2 }):Play()
		dropStroke.Color        = colors.Border
		dropStroke.Transparency = theme.Transparency.Border or 0.07
	end

	local function openDropdown()
		if self._open then return end
		self._open = true

		TweenService:Create(chevron, HOVER_INFO, { Rotation = 180 }):Play()
		TweenService:Create(dropBtn, HOVER_INFO, { BackgroundColor3 = colors.Surface3 }):Play()
		dropStroke.Color        = colors.Accent
		dropStroke.Transparency = 0

		local itemH        = ddCfg.ItemHeight
		local maxVis       = ddCfg.MaxVisible
		local visibleCount = math.min(#self._items, maxVis)
		local searchH      = 34
		local panelH       = searchH + visibleCount * itemH + 8

		-- Build panel
		dropPanel = Instance.new("Frame")
		dropPanel.Name                   = "DropPanel"
		dropPanel.Size                   = UDim2.new(0, dropBtn.AbsoluteSize.X, 0, 0)  -- start collapsed
		dropPanel.Position               = UDim2.fromOffset(
			dropBtn.AbsolutePosition.X,
			dropBtn.AbsolutePosition.Y + ddCfg.Height + 4
		)
		dropPanel.BackgroundColor3       = colors.Surface2
		dropPanel.BackgroundTransparency = 0
		dropPanel.BorderSizePixel        = 0
		dropPanel.ZIndex                 = 200
		dropPanel.ClipsDescendants       = true

		-- Find ScreenGui
		local sg = row
		while sg and not sg:IsA("ScreenGui") do
			sg = sg.Parent
		end
		if not sg then return end

		dropPanel.Parent = sg

		local panelCorner = Instance.new("UICorner")
		panelCorner.CornerRadius = UDim.new(0, radius.Button or 6)
		panelCorner.Parent = dropPanel

		local panelStroke = Instance.new("UIStroke")
		panelStroke.Color        = colors.Accent
		panelStroke.Transparency = 0.60
		panelStroke.Thickness    = 1
		panelStroke.Parent       = dropPanel

		-- Search box
		local searchContainer = Instance.new("Frame")
		searchContainer.Name             = "SearchContainer"
		searchContainer.Size             = UDim2.new(1, -8, 0, 26)
		searchContainer.Position         = UDim2.fromOffset(4, 4)
		searchContainer.BackgroundColor3 = colors.Surface3
		searchContainer.BorderSizePixel  = 0
		searchContainer.ZIndex           = 201
		searchContainer.Parent           = dropPanel

		local searchCorner = Instance.new("UICorner")
		searchCorner.CornerRadius = UDim.new(0, radius.Small or 4)
		searchCorner.Parent = searchContainer

		local searchBox = Instance.new("TextBox")
		searchBox.Name               = "SearchBox"
		searchBox.Size               = UDim2.new(1, -8, 1, 0)
		searchBox.Position           = UDim2.fromOffset(8, 0)
		searchBox.BackgroundTransparency = 1
		searchBox.Text               = ""
		searchBox.PlaceholderText    = "Search..."
		searchBox.TextColor3         = colors.Text
		searchBox.PlaceholderColor3  = colors.TextMuted
		searchBox.TextSize           = fontSizes.Sm or 12
		searchBox.Font               = fonts.Body
		searchBox.ClearTextOnFocus   = false
		searchBox.ZIndex             = 202
		searchBox.Parent             = searchContainer

		-- Scrolling frame for items
		local scrollFrame = Instance.new("ScrollingFrame")
		scrollFrame.Name                 = "ScrollFrame"
		scrollFrame.Size                 = UDim2.new(1, 0, 1, -searchH)
		scrollFrame.Position             = UDim2.fromOffset(0, searchH)
		scrollFrame.BackgroundTransparency = 1
		scrollFrame.BorderSizePixel      = 0
		scrollFrame.ScrollBarThickness   = 3
		scrollFrame.ScrollBarImageColor3 = colors.Accent
		scrollFrame.CanvasSize           = UDim2.fromOffset(0, 0)
		scrollFrame.AutomaticCanvasSize  = Enum.AutomaticSize.Y
		scrollFrame.ZIndex               = 201
		scrollFrame.Parent               = dropPanel

		local itemLayout = Instance.new("UIListLayout")
		itemLayout.FillDirection       = Enum.FillDirection.Vertical
		itemLayout.SortOrder           = Enum.SortOrder.LayoutOrder
		itemLayout.Padding             = UDim.new(0, 1)
		itemLayout.Parent              = scrollFrame

		local itemPadding = Instance.new("UIPadding")
		itemPadding.PaddingLeft   = UDim.new(0, 4)
		itemPadding.PaddingRight  = UDim.new(0, 4)
		itemPadding.PaddingTop    = UDim.new(0, 2)
		itemPadding.PaddingBottom = UDim.new(0, 2)
		itemPadding.Parent        = scrollFrame

		self._dropPanel  = dropPanel
		self._scrollFrame = scrollFrame

		local function buildItems(filter)
			-- Clear existing items
			for _, child in ipairs(scrollFrame:GetChildren()) do
				if child:IsA("TextButton") or child:IsA("Frame") then
					child:Destroy()
				end
			end

			local filtered = {}
			for _, item in ipairs(self._items) do
				local itemStr = tostring(item)
				if filter == "" or itemStr:lower():find(filter:lower(), 1, true) then
					table.insert(filtered, item)
				end
			end

			for i, item in ipairs(filtered) do
				local itemStr    = tostring(item)
				local isSelected = self._value == item

				local itemBtn = Instance.new("TextButton")
				itemBtn.Name                   = "Item_" .. i
				itemBtn.Size                   = UDim2.new(1, 0, 0, itemH)
				itemBtn.BackgroundColor3       = isSelected and colors.AccentSoft or Color3.fromRGB(0,0,0)
				itemBtn.BackgroundTransparency = isSelected and (theme.Transparency.AccentSoft or 0.15) or 1
				itemBtn.BorderSizePixel        = 0
				itemBtn.Text                   = ""
				itemBtn.AutoButtonColor        = false
				itemBtn.LayoutOrder            = i
				itemBtn.ZIndex                 = 202
				itemBtn.Parent                 = scrollFrame

				local itemCorner = Instance.new("UICorner")
				itemCorner.CornerRadius = UDim.new(0, radius.Small or 4)
				itemCorner.Parent = itemBtn

				local itemLabel = Instance.new("TextLabel")
				itemLabel.Name                   = "ItemLabel"
				itemLabel.Size                   = UDim2.new(1, -10, 1, 0)
				itemLabel.Position               = UDim2.fromOffset(10, 0)
				itemLabel.BackgroundTransparency = 1
				itemLabel.Text                   = itemStr
				itemLabel.TextColor3             = isSelected and colors.Accent or colors.Text
				itemLabel.TextSize               = fontSizes.Base or 13
				itemLabel.Font                   = isSelected and (fonts.SemiBold or fonts.Heading) or fonts.Body
				itemLabel.TextXAlignment         = Enum.TextXAlignment.Left
				itemLabel.ZIndex                 = 203
				itemLabel.Parent                 = itemBtn

				-- Hover
				itemBtn.MouseEnter:Connect(function()
					if not isSelected then
						TweenService:Create(itemBtn, HOVER_INFO, { BackgroundTransparency = 0.94 }):Play()
						itemBtn.BackgroundColor3 = colors.Surface3
					end
				end)

				itemBtn.MouseLeave:Connect(function()
					if not isSelected then
						TweenService:Create(itemBtn, HOVER_INFO, { BackgroundTransparency = 1 }):Play()
					end
				end)

				-- Select
				itemBtn.MouseButton1Click:Connect(function()
					self:Set(item)
					closeDropdown()
				end)
			end
		end

		buildItems("")

		-- Search filtering
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			buildItems(searchBox.Text)
		end)

		-- Expand panel animation
		TweenService:Create(dropPanel, OPEN_INFO, {
			Size = UDim2.new(0, dropBtn.AbsoluteSize.X, 0, panelH),
		}):Play()

		-- Close on outside click
		local outsideConn
		outsideConn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local pos     = input.Position
				local panelAbs = dropPanel.AbsolutePosition
				local panelSz  = dropPanel.AbsoluteSize
				local btnAbs   = dropBtn.AbsolutePosition
				local btnSz    = dropBtn.AbsoluteSize

				local inPanel = pos.X >= panelAbs.X and pos.X <= panelAbs.X + panelSz.X
					and pos.Y >= panelAbs.Y and pos.Y <= panelAbs.Y + panelSz.Y
				local inBtn   = pos.X >= btnAbs.X and pos.X <= btnAbs.X + btnSz.X
					and pos.Y >= btnAbs.Y and pos.Y <= btnAbs.Y + btnSz.Y

				if not inPanel and not inBtn then
					outsideConn:Disconnect()
					closeDropdown()
				end
			end
		end)
	end

	-- Toggle open/close
	local clickConn = dropBtn.MouseButton1Click:Connect(function()
		if self._open then
			closeDropdown()
		else
			openDropdown()
		end
	end)

	local hoverConn = dropBtn.MouseEnter:Connect(function()
		if not self._open then
			TweenService:Create(dropBtn, HOVER_INFO, { BackgroundColor3 = colors.Surface3 }):Play()
		end
	end)

	local leaveConn = dropBtn.MouseLeave:Connect(function()
		if not self._open then
			TweenService:Create(dropBtn, HOVER_INFO, { BackgroundColor3 = colors.Surface2 }):Play()
		end
	end)

	table.insert(self._connections, clickConn)
	table.insert(self._connections, hoverConn)
	table.insert(self._connections, leaveConn)

	self._closeDropdown = closeDropdown

	return self
end

--- Set selected value
---@param value any
function Dropdown:Set(value: any)
	self._value = value
	local colors = self._theme.Colors

	if value then
		self._selectedLabel.Text       = tostring(value)
		self._selectedLabel.TextColor3 = colors.Text
	else
		self._selectedLabel.Text       = "Select..."
		self._selectedLabel.TextColor3 = colors.TextMuted
	end

	if self._callback then
		task.spawn(self._callback, value)
	end
end

--- Get current selected value
---@return any
function Dropdown:Get(): any
	return self._value
end

--- Replace items list
---@param items table
function Dropdown:SetItems(items: table)
	self._items = items or {}
	if self._open then
		self._closeDropdown()
	end
end

--- Destroy the dropdown component
function Dropdown:Destroy()
	if self._destroyed then return end
	self._destroyed = true

	if self._open then
		self._closeDropdown()
	end

	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)

	if self._row then
		self._row:Destroy()
	end
end

return Dropdown
