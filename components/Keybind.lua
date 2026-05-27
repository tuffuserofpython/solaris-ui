-- libui/components/Keybind.lua
-- Keybind picker component for LibUI

local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")

local Keybind = {}
Keybind.__index = Keybind

local HOVER_INFO      = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TRANSITION_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local IGNORED_KEYS = {
	[Enum.KeyCode.Unknown]   = true,
	[Enum.KeyCode.Escape]    = true,
}

--- Create a new keybind picker
---@param parent GuiObject Parent container
---@param options table { Label, Description, Default, Callback }
---@param theme table
---@return table Keybind object
function Keybind.new(parent: GuiObject, options: table, theme: table)
	assert(parent, "Keybind.new: parent is nil")

	local colors    = theme.Colors
	local fonts     = theme.Fonts
	local fontSizes = theme.FontSizes
	local spacing   = theme.Spacing
	local radius    = theme.Radius

	local self         = setmetatable({}, Keybind)
	self._theme        = theme
	self._connections  = {}
	self._currentKey   = options.Default or Enum.KeyCode.RightShift
	self._listening    = false
	self._callback     = options.Callback
	self._destroyed    = false

	-- Row frame
	local row = Instance.new("Frame")
	row.Name                   = "KeybindRow"
	row.Size                   = UDim2.new(1, 0, 0, 46)
	row.BackgroundColor3       = colors.Surface
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

	-- Label
	local labelFrame = Instance.new("Frame")
	labelFrame.Name                   = "LabelFrame"
	labelFrame.Size                   = UDim2.new(1, -110, 1, 0)
	labelFrame.BackgroundTransparency = 1
	labelFrame.Position               = UDim2.fromOffset(spacing.Sm or 8, 0)
	labelFrame.Parent                 = row

	local label = Instance.new("TextLabel")
	label.Name                  = "Label"
	label.Size                  = UDim2.new(1, 0, 0, 20)
	label.Position              = UDim2.new(0, 0, 0.5, -10)
	label.BackgroundTransparency = 1
	label.Text                  = options.Label or "Keybind"
	label.TextColor3            = colors.Text
	label.TextSize              = fontSizes.Base or 13
	label.Font                  = fonts.Body
	label.TextXAlignment        = Enum.TextXAlignment.Left
	label.Parent                = labelFrame

	if options.Description and #options.Description > 0 then
		label.Position = UDim2.fromOffset(0, 6)
		label.Size     = UDim2.new(1, 0, 0, 18)

		local desc = Instance.new("TextLabel")
		desc.Name                   = "Description"
		desc.Size                   = UDim2.new(1, 0, 0, 14)
		desc.Position               = UDim2.fromOffset(0, 25)
		desc.BackgroundTransparency = 1
		desc.Text                   = options.Description
		desc.TextColor3             = colors.TextMuted
		desc.TextSize               = fontSizes.Xs or 10
		desc.Font                   = fonts.Caption
		desc.TextXAlignment         = Enum.TextXAlignment.Left
		desc.Parent                 = labelFrame
	end

	-- Keybind button
	local keyBtn = Instance.new("TextButton")
	keyBtn.Name                   = "KeyBtn"
	keyBtn.Size                   = UDim2.fromOffset(90, 28)
	keyBtn.Position               = UDim2.new(1, -98, 0.5, -14)
	keyBtn.BackgroundColor3       = colors.Surface3
	keyBtn.BorderSizePixel        = 0
	keyBtn.Text                   = Keybind._formatKey(self._currentKey)
	keyBtn.TextColor3             = colors.Text
	keyBtn.TextSize               = fontSizes.Sm or 12
	keyBtn.Font                   = fonts.SemiBold or fonts.Heading
	keyBtn.ZIndex                 = row.ZIndex + 1
	keyBtn.AutoButtonColor        = false
	keyBtn.Parent                 = row

	local keyCorner = Instance.new("UICorner")
	keyCorner.CornerRadius = UDim.new(0, radius.Small or 4)
	keyCorner.Parent = keyBtn

	local keyStroke = Instance.new("UIStroke")
	keyStroke.Color        = colors.Border
	keyStroke.Transparency = theme.Transparency.Border or 0.07
	keyStroke.Thickness    = 1
	keyStroke.Parent       = keyBtn

	self._row       = row
	self._keyBtn    = keyBtn
	self._keyStroke = keyStroke

	-- Hover effects on row
	local rowHoverConn = row.MouseEnter:Connect(function()
		TweenService:Create(hoverBg, HOVER_INFO, { BackgroundTransparency = 0.95 }):Play()
	end)

	local rowLeaveConn = row.MouseLeave:Connect(function()
		TweenService:Create(hoverBg, HOVER_INFO, { BackgroundTransparency = 1 }):Play()
	end)

	-- Keybind button hover
	local btnHoverConn = keyBtn.MouseEnter:Connect(function()
		if not self._listening then
			TweenService:Create(keyBtn, HOVER_INFO, { BackgroundColor3 = colors.Surface2 }):Play()
		end
	end)

	local btnLeaveConn = keyBtn.MouseLeave:Connect(function()
		if not self._listening then
			TweenService:Create(keyBtn, HOVER_INFO, { BackgroundColor3 = colors.Surface3 }):Play()
		end
	end)

	-- Click to start listening
	local btnClickConn = keyBtn.MouseButton1Click:Connect(function()
		if not self._listening then
			self:_startListening()
		end
	end)

	table.insert(self._connections, rowHoverConn)
	table.insert(self._connections, rowLeaveConn)
	table.insert(self._connections, btnHoverConn)
	table.insert(self._connections, btnLeaveConn)
	table.insert(self._connections, btnClickConn)

	return self
end

--- Start listening for a key press
function Keybind:_startListening()
	self._listening = true

	local colors = self._theme.Colors
	local fonts  = self._theme.Fonts

	TweenService:Create(self._keyBtn, HOVER_INFO, {
		BackgroundColor3 = colors.AccentSoft or colors.Accent,
		TextColor3       = colors.Accent,
	}):Play()
	self._keyStroke.Color        = colors.Accent
	self._keyStroke.Transparency = 0
	self._keyBtn.Text            = "Press a key..."

	local inputConn
	inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not self._listening then
			inputConn:Disconnect()
			return
		end

		-- Cancel on Escape
		if input.KeyCode == Enum.KeyCode.Escape then
			self:_stopListening()
			inputConn:Disconnect()
			return
		end

		-- Only capture keyboard inputs
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if not IGNORED_KEYS[input.KeyCode] then
				self:_stopListening()
				inputConn:Disconnect()
				self:SetKey(input.KeyCode)
				if self._callback then
					task.spawn(self._callback, input.KeyCode)
				end
			end
		end
	end)

	table.insert(self._connections, inputConn)
end

--- Stop listening mode and restore UI
function Keybind:_stopListening()
	self._listening = false

	local colors = self._theme.Colors

	TweenService:Create(self._keyBtn, HOVER_INFO, {
		BackgroundColor3 = colors.Surface3,
		TextColor3       = colors.Text,
	}):Play()
	self._keyStroke.Color        = colors.Border
	self._keyStroke.Transparency = self._theme.Transparency.Border or 0.07
	self._keyBtn.Text            = Keybind._formatKey(self._currentKey)
end

--- Format a KeyCode to a readable string
---@param keyCode Enum.KeyCode
---@return string
function Keybind._formatKey(keyCode: EnumItem): string
	if not keyCode then return "None" end
	local name = keyCode.Name
	-- Common remappings for cleaner display
	local remaps = {
		LeftControl    = "L.Ctrl",
		RightControl   = "R.Ctrl",
		LeftShift      = "L.Shift",
		RightShift     = "R.Shift",
		LeftAlt        = "L.Alt",
		RightAlt       = "R.Alt",
		LeftSuper      = "L.Win",
		RightSuper     = "R.Win",
		Return         = "Enter",
		BackSpace      = "Backspace",
		CapsLock       = "Caps",
		Tab            = "Tab",
		Space          = "Space",
		Delete         = "Delete",
		Insert         = "Insert",
		Home           = "Home",
		End            = "End",
		PageUp         = "PgUp",
		PageDown       = "PgDn",
	}
	return remaps[name] or name
end

--- Get the current bound key
---@return Enum.KeyCode
function Keybind:GetKey(): EnumItem
	return self._currentKey
end

--- Set the bound key programmatically
---@param keyCode Enum.KeyCode
function Keybind:SetKey(keyCode: EnumItem)
	self._currentKey = keyCode
	self._keyBtn.Text = Keybind._formatKey(keyCode)
end

--- Destroy the keybind component
function Keybind:Destroy()
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

return Keybind
