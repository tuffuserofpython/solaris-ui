-- libui/components/MultiDropdown.lua
-- Multi-select dropdown component for LibUI

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local MultiDropdown = {}
MultiDropdown.__index = MultiDropdown

local OPEN_INFO  = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local CLOSE_INFO = TweenInfo.new(0.20, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
local HOVER_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

--- Create a multi-select dropdown component
---@param parent GuiObject
---@param options table { Label, Description, Items, Default, Callback }
---@param theme table
---@return table MultiDropdown object
function MultiDropdown.new(parent: GuiObject, options: table, theme: table)
	assert(parent, "MultiDropdown.new: parent is nil")

	local colors    = theme.Colors
	local fonts     = theme.Fonts
	local fontSizes = theme.FontSizes
	local radius    = theme.Radius
	local ddCfg     = (theme.Components and theme.Components.Dropdown) or
		{ Height = 36, ItemHeight = 32, MaxVisible = 5 }

	local self        = setmetatable({}, MultiDropdown)
	self._theme       = theme
	self._connections = {}
	self._items       = options.Items or {}
	self._selected    = {}
	self._callback    = options.Callback
	self._destroyed   = false
	self._open        = false

	-- Initialize with defaults
	if options.Default and type(options.Default) == "table" then
		for _, v in ipairs(options.Default) do
			self._selected[v] = true
		end
	end

	local hasDesc = options.Description and #options.Description > 0
	local rowH    = hasDesc and 68 or 52

	-- Row container
	local row = Instance.new("Frame")
	row.Name                   = "MultiDropdownRow"
	row.Size                   = UDim2.new(1, 0, 0, rowH)
	row.BackgroundTransparency = 1
	row.BorderSizePixel        = 0
	row.ClipsDescendants       = false
	row.Parent                 = parent

	local labelY = 6
	local dropY  = hasDesc and 44 or 30

	-- Label
	local label = Instance.new("TextLabel")
	label.Name                  = "Label"
	label.Size                  = UDim2.new(1, -16, 0, 18)
	label.Position              = UDim2.fromOffset(8, labelY)
	label.BackgroundTransparency = 1
	label.Text                  = options.Label or "Multi Select"
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

	-- Selected count badge / text
	local selectedLabel = Instance.new("TextLabel")
	selectedLabel.Name                  = "SelectedLabel"
	selectedLabel.Size                  = UDim2.new(1, -70, 1, 0)
	selectedLabel.Position              = UDim2.fromOffset(12, 0)
	selectedLabel.BackgroundTransparency = 1
	selectedLabel.Text                  = "Select..."
	selectedLabel.TextColor3            = colors.TextMuted
	selectedLabel.TextSize              = fontSizes.Base or 13
	selectedLabel.Font                  = fonts.Body
	selectedLabel.TextXAlignment        = Enum.TextXAlignment.Left
	selectedLabel.TextTruncate          = Enum.TextTruncate.AtEnd
	selectedLabel.ZIndex                = dropBtn.ZIndex + 1
	selectedLabel.Parent                = dropBtn

	-- Count badge
	local badge = Instance.new("Frame")
	badge.Name             = "Badge"
	badge.Size             = UDim2.fromOffset(40, 20)
	badge.Position         = UDim2.new(1, -60, 0.5, -10)
	badge.BackgroundColor3 = colors.AccentSoft or colors.Accent
	badge.BackgroundTransparency = theme.Transparency.AccentSoft or 0.15
	badge.BorderSizePixel  = 0
	badge.Visible          = false
	badge.ZIndex           = dropBtn.ZIndex + 1
	badge.Parent           = dropBtn

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 10)
	badgeCorner.Parent = badge

	local badgeLabel = Instance.new("TextLabel")
	badgeLabel.Name                  = "BadgeLabel"
	badgeLabel.Size                  = UDim2.fromScale(1, 1)
	badgeLabel.BackgroundTransparency = 1
	badgeLabel.Text                  = "0"
	badgeLabel.TextColor3            = colors.Accent
	badgeLabel.TextSize              = fontSizes.Xs or 10
	badgeLabel.Font                  = fonts.SemiBold or fonts.Heading
	badgeLabel.ZIndex                = badge.ZIndex + 1
	badgeLabel.Parent                = badge

	-- Chevron
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

	self._row           = row
	self._dropBtn       = dropBtn
	self._selectedLabel = selectedLabel
	self._badge         = badge
	self._badgeLabel    = badgeLabel
	self._chevron       = chevron
	self._dropStroke    = dropStroke
	self._dropPanel     = nil
	self._ddCfg         = ddCfg

	local function updateDisplay()
		local count = 0
		for _ in pairs(self._selected) do count = count + 1 end

		if count == 0 then
			selectedLabel.Text       = "Select..."
			selectedLabel.TextColor3 = colors.TextMuted
			badge.Visible            = false
		elseif count == 1 then
			local selectedItem
			for k in pairs(self._selected) do selectedItem = k break end
			selectedLabel.Text       = tostring(selectedItem)
			selectedLabel.TextColor3 = colors.Text
			badge.Visible            = false
		else
			selectedLabel.Text       = count .. " selected"
			selectedLabel.TextColor3 = colors.Text
			badge.Visible            = true
			badgeLabel.Text          = tostring(count)
		end
	end

	updateDisplay()
	self._updateDisplay = updateDisplay

	local dropPanel = nil

	local function closeDropdown()
		if not self._open then return end
		self._open = false

		if dropPanel then
			TweenService:Create(dropPanel, CLOSE_INFO, {
				Size = UDim2.new(dropPanel.Size.X.Scale, dropPanel.Size.X.Offset, 0, 0),
			}):Play()
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

	local itemButtons = {}

	local function buildItems(filter)
		-- Clear
		for _, v in ipairs(itemButtons) do
			if v and v.Parent then v:Destroy() end
		end
		table.clear(itemButtons)
		if not self._scrollFrame then return end

		for _, child in ipairs(self._scrollFrame:GetChildren()) do
			if child:IsA("TextButton") or child:IsA("Frame") then
				child:Destroy()
			end
		end

		local filtered = {}
		for _, item in ipairs(self._items) do
			local s = tostring(item)
			if filter == "" or s:lower():find(filter:lower(), 1, true) then
				table.insert(filtered, item)
			end
		end

		for i, item in ipairs(filtered) do
			local isSelected = self._selected[item] == true

			local itemBtn = Instance.new("TextButton")
			itemBtn.Name                   = "Item_" .. i
			itemBtn.Size                   = UDim2.new(1, 0, 0, ddCfg.ItemHeight)
			itemBtn.BackgroundColor3       = isSelected and colors.AccentSoft or Color3.fromRGB(0,0,0)
			itemBtn.BackgroundTransparency = isSelected and (theme.Transparency.AccentSoft or 0.15) or 1
			itemBtn.BorderSizePixel        = 0
			itemBtn.Text                   = ""
			itemBtn.AutoButtonColor        = false
			itemBtn.LayoutOrder            = i
			itemBtn.ZIndex                 = 202
			itemBtn.Parent                 = self._scrollFrame

			local iBtnCorner = Instance.new("UICorner")
			iBtnCorner.CornerRadius = UDim.new(0, radius.Small or 4)
			iBtnCorner.Parent = itemBtn

			-- Checkbox
			local checkbox = Instance.new("Frame")
			checkbox.Name             = "Checkbox"
			checkbox.Size             = UDim2.fromOffset(14, 14)
			checkbox.Position         = UDim2.fromOffset(8, (ddCfg.ItemHeight - 14) / 2)
			checkbox.BackgroundColor3 = isSelected and colors.Accent or Color3.fromRGB(0,0,0)
			checkbox.BackgroundTransparency = isSelected and 0 or 1
			checkbox.BorderSizePixel  = 0
			checkbox.ZIndex           = 203
			checkbox.Parent           = itemBtn

			local cbCorner = Instance.new("UICorner")
			cbCorner.CornerRadius = UDim.new(0, 3)
			cbCorner.Parent = checkbox

			local cbStroke = Instance.new("UIStroke")
			cbStroke.Color        = isSelected and colors.Accent or colors.Border
			cbStroke.Transparency = isSelected and 0 or (theme.Transparency.Border or 0.07)
			cbStroke.Thickness    = 1
			cbStroke.Parent       = checkbox

			-- Checkmark
			local checkmark = Instance.new("TextLabel")
			checkmark.Name                  = "Checkmark"
			checkmark.Size                  = UDim2.fromScale(1, 1)
			checkmark.BackgroundTransparency = 1
			checkmark.Text                  = "✓"
			checkmark.TextColor3            = colors.White
			checkmark.TextSize              = 10
			checkmark.Font                  = fonts.Heading
			checkmark.Visible               = isSelected
			checkmark.ZIndex                = 204
			checkmark.Parent                = checkbox

			local itemLabel = Instance.new("TextLabel")
			itemLabel.Name                   = "ItemLabel"
			itemLabel.Size                   = UDim2.new(1, -38, 1, 0)
			itemLabel.Position               = UDim2.fromOffset(30, 0)
			itemLabel.BackgroundTransparency = 1
			itemLabel.Text                   = tostring(item)
			itemLabel.TextColor3             = isSelected and colors.Accent or colors.Text
			itemLabel.TextSize               = fontSizes.Base or 13
			itemLabel.Font                   = fonts.Body
			itemLabel.TextXAlignment         = Enum.TextXAlignment.Left
			itemLabel.ZIndex                 = 203
			itemLabel.Parent                 = itemBtn

			table.insert(itemButtons, itemBtn)

			itemBtn.MouseEnter:Connect(function()
				if not self._selected[item] then
					TweenService:Create(itemBtn, HOVER_INFO, {
						BackgroundColor3    = colors.Surface3,
						BackgroundTransparency = 0.94,
					}):Play()
				end
			end)

			itemBtn.MouseLeave:Connect(function()
				if not self._selected[item] then
					TweenService:Create(itemBtn, HOVER_INFO, { BackgroundTransparency = 1 }):Play()
				end
			end)

			itemBtn.MouseButton1Click:Connect(function()
				if self._selected[item] then
					self._selected[item] = nil
					TweenService:Create(itemBtn, HOVER_INFO, { BackgroundTransparency = 1 }):Play()
					itemBtn.BackgroundColor3 = Color3.fromRGB(0,0,0)
					TweenService:Create(checkbox, HOVER_INFO, { BackgroundTransparency = 1 }):Play()
					cbStroke.Color        = colors.Border
					cbStroke.Transparency = theme.Transparency.Border or 0.07
					checkmark.Visible     = false
					itemLabel.TextColor3  = colors.Text
					itemLabel.Font        = fonts.Body
				else
					self._selected[item] = true
					TweenService:Create(itemBtn, HOVER_INFO, {
						BackgroundColor3    = colors.AccentSoft,
						BackgroundTransparency = theme.Transparency.AccentSoft or 0.15,
					}):Play()
					TweenService:Create(checkbox, HOVER_INFO, { BackgroundTransparency = 0 }):Play()
					checkbox.BackgroundColor3 = colors.Accent
					cbStroke.Color        = colors.Accent
					cbStroke.Transparency = 0
					checkmark.Visible     = true
					itemLabel.TextColor3  = colors.Accent
					itemLabel.Font        = fonts.SemiBold or fonts.Heading
				end

				updateDisplay()

				-- Build selected values list
				local selectedValues = {}
				for k in pairs(self._selected) do
					table.insert(selectedValues, k)
				end

				if self._callback then
					task.spawn(self._callback, selectedValues)
				end
			end)
		end
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

		dropPanel = Instance.new("Frame")
		dropPanel.Name                   = "MultiDropPanel"
		dropPanel.Size                   = UDim2.new(0, dropBtn.AbsoluteSize.X, 0, 0)
		dropPanel.Position               = UDim2.fromOffset(
			dropBtn.AbsolutePosition.X,
			dropBtn.AbsolutePosition.Y + ddCfg.Height + 4
		)
		dropPanel.BackgroundColor3       = colors.Surface2
		dropPanel.BorderSizePixel        = 0
		dropPanel.ZIndex                 = 200
		dropPanel.ClipsDescendants       = true

		local sg = row
		while sg and not sg:IsA("ScreenGui") do sg = sg.Parent end
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

		-- Search
		local searchContainer = Instance.new("Frame")
		searchContainer.Name             = "SearchContainer"
		searchContainer.Size             = UDim2.new(1, -8, 0, 26)
		searchContainer.Position         = UDim2.fromOffset(4, 4)
		searchContainer.BackgroundColor3 = colors.Surface3
		searchContainer.BorderSizePixel  = 0
		searchContainer.ZIndex           = 201
		searchContainer.Parent           = dropPanel

		local sCor = Instance.new("UICorner")
		sCor.CornerRadius = UDim.new(0, 3)
		sCor.Parent = searchContainer

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

		-- Scroll frame
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

		local listLayout = Instance.new("UIListLayout")
		listLayout.FillDirection       = Enum.FillDirection.Vertical
		listLayout.SortOrder           = Enum.SortOrder.LayoutOrder
		listLayout.Padding             = UDim.new(0, 1)
		listLayout.Parent              = scrollFrame

		local lPad = Instance.new("UIPadding")
		lPad.PaddingLeft   = UDim.new(0, 4)
		lPad.PaddingRight  = UDim.new(0, 4)
		lPad.PaddingTop    = UDim.new(0, 2)
		lPad.PaddingBottom = UDim.new(0, 2)
		lPad.Parent        = scrollFrame

		self._dropPanel   = dropPanel
		self._scrollFrame = scrollFrame

		buildItems("")

		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			buildItems(searchBox.Text)
		end)

		TweenService:Create(dropPanel, OPEN_INFO, {
			Size = UDim2.new(0, dropBtn.AbsoluteSize.X, 0, panelH),
		}):Play()

		-- Outside click to close
		local outsideConn
		outsideConn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local pos      = input.Position
				local pAbs     = dropPanel.AbsolutePosition
				local pSz      = dropPanel.AbsoluteSize
				local bAbs     = dropBtn.AbsolutePosition
				local bSz      = dropBtn.AbsoluteSize
				local inPanel  = pos.X >= pAbs.X and pos.X <= pAbs.X + pSz.X
					and pos.Y >= pAbs.Y and pos.Y <= pAbs.Y + pSz.Y
				local inBtn    = pos.X >= bAbs.X and pos.X <= bAbs.X + bSz.X
					and pos.Y >= bAbs.Y and pos.Y <= bAbs.Y + bSz.Y
				if not inPanel and not inBtn then
					outsideConn:Disconnect()
					closeDropdown()
				end
			end
		end)
	end

	local clickConn = dropBtn.MouseButton1Click:Connect(function()
		if self._open then closeDropdown() else openDropdown() end
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

--- Set selected values
---@param values table Array of values to select
function MultiDropdown:Set(values: table)
	self._selected = {}
	for _, v in ipairs(values) do
		self._selected[v] = true
	end
	self._updateDisplay()
end

--- Get current selected values
---@return table
function MultiDropdown:Get(): table
	local result = {}
	for k in pairs(self._selected) do
		table.insert(result, k)
	end
	return result
end

--- Destroy the multi-dropdown component
function MultiDropdown:Destroy()
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

return MultiDropdown
