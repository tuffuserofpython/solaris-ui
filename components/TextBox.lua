-- libui/components/TextBox.lua
-- Text input component for LibUI

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local TextBox = {}
TextBox.__index = TextBox

local HOVER_INFO  = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local FOCUS_INFO  = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

--- Create a new text input component
---@param parent GuiObject
---@param options table { Label, Description, Placeholder, Default, Callback, Validator }
---@param theme table
---@return table TextBox object
function TextBox.new(parent: GuiObject, options: table, theme: table)
	assert(parent, "TextBox.new: parent is nil")

	local colors    = theme.Colors
	local fonts     = theme.Fonts
	local fontSizes = theme.FontSizes
	local spacing   = theme.Spacing
	local radius    = theme.Radius
	local inputCfg  = (theme.Components and theme.Components.Input) or { Height = 36, PaddingH = 12 }

	local self        = setmetatable({}, TextBox)
	self._theme       = theme
	self._connections = {}
	self._value       = options.Default or ""
	self._callback    = options.Callback
	self._validator   = options.Validator
	self._destroyed   = false
	self._errorMsg    = nil
	self._focused     = false

	local hasDesc = options.Description and #options.Description > 0
	local rowH    = hasDesc and 84 or 68

	-- Row container
	local row = Instance.new("Frame")
	row.Name                   = "TextBoxRow"
	row.Size                   = UDim2.new(1, 0, 0, rowH)
	row.BackgroundTransparency = 1
	row.BorderSizePixel        = 0
	row.Parent                 = parent

	local labelY = 6
	local inputY = hasDesc and 44 or 32

	-- Label
	local label = Instance.new("TextLabel")
	label.Name                  = "Label"
	label.Size                  = UDim2.new(1, -16, 0, 18)
	label.Position              = UDim2.fromOffset(spacing.Sm or 8, labelY)
	label.BackgroundTransparency = 1
	label.Text                  = options.Label or "Input"
	label.TextColor3            = colors.Text
	label.TextSize              = fontSizes.Base or 13
	label.Font                  = fonts.Body
	label.TextXAlignment        = Enum.TextXAlignment.Left
	label.Parent                = row

	if hasDesc then
		local desc = Instance.new("TextLabel")
		desc.Name                   = "Description"
		desc.Size                   = UDim2.new(1, -16, 0, 13)
		desc.Position               = UDim2.fromOffset(spacing.Sm or 8, labelY + 19)
		desc.BackgroundTransparency = 1
		desc.Text                   = options.Description
		desc.TextColor3             = colors.TextMuted
		desc.TextSize               = fontSizes.Xs or 10
		desc.Font                   = fonts.Caption
		desc.TextXAlignment         = Enum.TextXAlignment.Left
		desc.Parent                 = row
	end

	-- Input container
	local inputContainer = Instance.new("Frame")
	inputContainer.Name             = "InputContainer"
	inputContainer.Size             = UDim2.new(1, -16, 0, inputCfg.Height)
	inputContainer.Position         = UDim2.fromOffset(8, inputY)
	inputContainer.BackgroundColor3 = colors.Surface2
	inputContainer.BorderSizePixel  = 0
	inputContainer.ZIndex           = row.ZIndex + 1
	inputContainer.Parent           = row

	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, radius.Button or 6)
	inputCorner.Parent = inputContainer

	-- Border stroke (animated on focus)
	local stroke = Instance.new("UIStroke")
	stroke.Color        = colors.Border
	stroke.Transparency = theme.Transparency.Border or 0.07
	stroke.Thickness    = 1
	stroke.Parent       = inputContainer
	self._stroke = stroke

	-- Text box
	local textBox = Instance.new("TextBox")
	textBox.Name                   = "Input"
	textBox.Size                   = UDim2.new(1, -(inputCfg.PaddingH * 2 + 24), 1, 0)
	textBox.Position               = UDim2.fromOffset(inputCfg.PaddingH, 0)
	textBox.BackgroundTransparency = 1
	textBox.Text                   = self._value
	textBox.PlaceholderText        = options.Placeholder or ""
	textBox.TextColor3             = colors.Text
	textBox.PlaceholderColor3      = colors.TextMuted
	textBox.TextSize               = fontSizes.Base or 13
	textBox.Font                   = fonts.Body
	textBox.TextXAlignment         = Enum.TextXAlignment.Left
	textBox.ClearTextOnFocus       = false
	textBox.ZIndex                 = inputContainer.ZIndex + 1
	textBox.Parent                 = inputContainer

	-- Clear button (×)
	local clearBtn = Instance.new("TextButton")
	clearBtn.Name                  = "ClearBtn"
	clearBtn.Size                  = UDim2.fromOffset(20, 20)
	clearBtn.Position              = UDim2.new(1, -24, 0.5, -10)
	clearBtn.BackgroundTransparency = 1
	clearBtn.Text                  = "×"
	clearBtn.TextColor3            = colors.TextMuted
	clearBtn.TextSize              = 18
	clearBtn.Font                  = fonts.Heading
	clearBtn.Visible               = #self._value > 0
	clearBtn.ZIndex                = inputContainer.ZIndex + 2
	clearBtn.Parent                = inputContainer

	-- Error label
	local errorLabel = Instance.new("TextLabel")
	errorLabel.Name                  = "ErrorLabel"
	errorLabel.Size                  = UDim2.new(1, -16, 0, 13)
	errorLabel.Position              = UDim2.fromOffset(8, inputY + inputCfg.Height + 3)
	errorLabel.BackgroundTransparency = 1
	errorLabel.Text                  = ""
	errorLabel.TextColor3            = colors.Danger
	errorLabel.TextSize              = fontSizes.Xs or 10
	errorLabel.Font                  = fonts.Caption
	errorLabel.TextXAlignment        = Enum.TextXAlignment.Left
	errorLabel.Visible               = false
	errorLabel.Parent                = row

	self._row         = row
	self._textBox     = textBox
	self._clearBtn    = clearBtn
	self._errorLabel  = errorLabel
	self._inputContainer = inputContainer

	-- Focus effects
	local focusConn = textBox.Focused:Connect(function()
		self._focused = true
		TweenService:Create(stroke, FOCUS_INFO, {
			Color        = colors.Accent,
			Transparency = 0,
		}):Play()
		TweenService:Create(inputContainer, FOCUS_INFO, {
			BackgroundColor3 = colors.Surface3,
		}):Play()
	end)

	local focusLostConn = textBox.FocusLost:Connect(function(enterPressed)
		self._focused = false
		local hasError = self._errorMsg ~= nil

		TweenService:Create(stroke, FOCUS_INFO, {
			Color        = hasError and colors.Danger or colors.Border,
			Transparency = hasError and 0 or (theme.Transparency.Border or 0.07),
		}):Play()
		TweenService:Create(inputContainer, FOCUS_INFO, {
			BackgroundColor3 = colors.Surface2,
		}):Play()

		local newValue = textBox.Text
		self._value = newValue
		clearBtn.Visible = #newValue > 0

		-- Validate
		if self._validator then
			local ok, msg = self._validator(newValue)
			if not ok then
				self:SetError(msg or "Invalid input")
				return
			else
				self:SetError(nil)
			end
		end

		if self._callback then
			task.spawn(self._callback, newValue)
		end
	end)

	-- Live update
	local changedConn = textBox:GetPropertyChangedSignal("Text"):Connect(function()
		local text = textBox.Text
		self._value = text
		clearBtn.Visible = #text > 0

		-- Clear error on type
		if self._errorMsg then
			self:SetError(nil)
		end
	end)

	-- Clear button
	local clearConn = clearBtn.MouseButton1Click:Connect(function()
		textBox.Text    = ""
		self._value     = ""
		clearBtn.Visible = false
		self:SetError(nil)
		if self._callback then
			task.spawn(self._callback, "")
		end
	end)

	-- Hover on clear
	local clearHoverConn = clearBtn.MouseEnter:Connect(function()
		TweenService:Create(clearBtn, HOVER_INFO, { TextColor3 = colors.Text }):Play()
	end)

	local clearLeaveConn = clearBtn.MouseLeave:Connect(function()
		TweenService:Create(clearBtn, HOVER_INFO, { TextColor3 = colors.TextMuted }):Play()
	end)

	table.insert(self._connections, focusConn)
	table.insert(self._connections, focusLostConn)
	table.insert(self._connections, changedConn)
	table.insert(self._connections, clearConn)
	table.insert(self._connections, clearHoverConn)
	table.insert(self._connections, clearLeaveConn)

	return self
end

--- Set text value programmatically
---@param text string
function TextBox:Set(text: string)
	self._value         = text
	self._textBox.Text  = text
	self._clearBtn.Visible = #text > 0
end

--- Get current text value
---@return string
function TextBox:Get(): string
	return self._value
end

--- Set or clear an error message
---@param msg string? nil to clear error
function TextBox:SetError(msg: string?)
	self._errorMsg = msg
	local colors = self._theme.Colors

	if msg then
		self._errorLabel.Text    = msg
		self._errorLabel.Visible = true
		TweenService:Create(self._stroke, FOCUS_INFO, {
			Color        = colors.Danger,
			Transparency = 0,
		}):Play()
		TweenService:Create(self._inputContainer, FOCUS_INFO, {
			BackgroundColor3 = colors.DangerSoft or colors.Surface2,
		}):Play()
	else
		self._errorLabel.Text    = ""
		self._errorLabel.Visible = false
		if not self._focused then
			TweenService:Create(self._stroke, FOCUS_INFO, {
				Color        = colors.Border,
				Transparency = self._theme.Transparency.Border or 0.07,
			}):Play()
			TweenService:Create(self._inputContainer, FOCUS_INFO, {
				BackgroundColor3 = colors.Surface2,
			}):Play()
		end
	end
end

--- Destroy the text box component
function TextBox:Destroy()
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

return TextBox
