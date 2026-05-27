-- libui/components/Modal.lua
-- Modal dialog component for LibUI

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Modal = {}
Modal.__index = Modal

local OPEN_INFO      = TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local CLOSE_INFO     = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
local BACKDROP_INFO  = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local HOVER_INFO     = TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

--- Create a new modal dialog
---@param screenGui ScreenGui The ScreenGui to mount the modal into
---@param options table { Title, Message, Buttons, Width }
---@param theme table
---@return table Modal object with :Show(), :Hide(), :Destroy()
function Modal.new(screenGui: ScreenGui, options: table, theme: table)
	assert(screenGui, "Modal.new: screenGui is nil")

	local colors    = theme.Colors
	local fonts     = theme.Fonts
	local fontSizes = theme.FontSizes
	local spacing   = theme.Spacing
	local radius    = theme.Radius
	local shadows   = theme.Shadows

	local self        = setmetatable({}, Modal)
	self._theme       = theme
	self._connections = {}
	self._destroyed   = false
	self._visible     = false
	self._screenGui   = screenGui

	local modalW   = options.Width or 400
	local title    = options.Title   or "Dialog"
	local message  = options.Message or ""
	local buttons  = options.Buttons or { { Label = "OK", Style = "primary", Callback = nil } }

	-- Backdrop overlay
	local backdrop = Instance.new("Frame")
	backdrop.Name                   = "ModalBackdrop"
	backdrop.Size                   = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3       = colors.Overlay or Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 1
	backdrop.BorderSizePixel        = 0
	backdrop.ZIndex                 = 600
	backdrop.Visible                = false
	backdrop.Parent                 = screenGui

	-- Shadow holder
	local shadowHolder = Instance.new("Frame")
	shadowHolder.Name                   = "ModalShadowHolder"
	shadowHolder.AnchorPoint            = Vector2.new(0.5, 0.5)
	shadowHolder.Position               = UDim2.fromScale(0.5, 0.5)
	shadowHolder.BackgroundTransparency = 1
	shadowHolder.BorderSizePixel        = 0
	shadowHolder.ZIndex                 = 601
	shadowHolder.Parent                 = backdrop

	-- Shadow image
	local shadowImg = Instance.new("ImageLabel")
	shadowImg.Size             = shadows.Popup.Size
	shadowImg.Position         = shadows.Popup.Position
	shadowImg.BackgroundTransparency = 1
	shadowImg.Image            = shadows.AssetId
	shadowImg.ImageColor3      = shadows.Popup.Color
	shadowImg.ImageTransparency = shadows.Popup.Transparency
	shadowImg.ScaleType        = Enum.ScaleType.Slice
	shadowImg.SliceCenter      = shadows.SliceRect
	shadowImg.ZIndex           = 601
	shadowImg.Parent           = shadowHolder

	-- Modal card
	local card = Instance.new("Frame")
	card.Name                   = "ModalCard"
	card.Size                   = UDim2.fromOffset(0, 0)  -- starts at zero, grows on open
	card.Position               = UDim2.fromScale(0, 0)
	card.AnchorPoint            = Vector2.new(0, 0)
	card.BackgroundColor3       = colors.Surface
	card.BackgroundTransparency = 0
	card.BorderSizePixel        = 0
	card.ClipsDescendants       = true
	card.ZIndex                 = 602
	card.Parent                 = shadowHolder

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, radius.Window or 12)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color        = colors.Border
	cardStroke.Transparency = theme.Transparency.Border or 0.07
	cardStroke.Thickness    = 1
	cardStroke.Parent       = card

	-- Header bar
	local headerH = 52
	local header = Instance.new("Frame")
	header.Name                   = "Header"
	header.Size                   = UDim2.new(1, 0, 0, headerH)
	header.BackgroundColor3       = colors.Surface2
	header.BackgroundTransparency = 0.40
	header.BorderSizePixel        = 0
	header.ZIndex                 = card.ZIndex + 1
	header.Parent                 = card

	-- Header divider
	local headerDiv = Instance.new("Frame")
	headerDiv.Name                   = "HeaderDiv"
	headerDiv.Size                   = UDim2.new(1, 0, 0, 1)
	headerDiv.Position               = UDim2.new(0, 0, 1, -1)
	headerDiv.BackgroundColor3       = colors.Border
	headerDiv.BackgroundTransparency = theme.Transparency.Border or 0.07
	headerDiv.BorderSizePixel        = 0
	headerDiv.ZIndex                 = header.ZIndex + 1
	headerDiv.Parent                 = header

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name                  = "Title"
	titleLabel.Size                  = UDim2.new(1, -48, 1, 0)
	titleLabel.Position              = UDim2.fromOffset(spacing.Lg or 16, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text                  = title
	titleLabel.TextColor3            = colors.Text
	titleLabel.TextSize              = fontSizes.Md or 14
	titleLabel.Font                  = fonts.Heading
	titleLabel.TextXAlignment        = Enum.TextXAlignment.Left
	titleLabel.ZIndex                = header.ZIndex + 1
	titleLabel.Parent                = header

	self._titleLabel = titleLabel

	-- Close X button in header
	local closeX = Instance.new("TextButton")
	closeX.Name                   = "CloseX"
	closeX.Size                   = UDim2.fromOffset(28, 28)
	closeX.Position               = UDim2.new(1, -38, 0.5, -14)
	closeX.BackgroundColor3       = colors.Surface3
	closeX.BackgroundTransparency = 1
	closeX.Text                   = "×"
	closeX.TextColor3             = colors.TextMuted
	closeX.TextSize               = 18
	closeX.Font                   = fonts.Heading
	closeX.ZIndex                 = header.ZIndex + 2
	closeX.Parent                 = header

	local closeXCorner = Instance.new("UICorner")
	closeXCorner.CornerRadius = UDim.new(1, 0)
	closeXCorner.Parent = closeX

	local closeXHoverConn = closeX.MouseEnter:Connect(function()
		TweenService:Create(closeX, HOVER_INFO, {
			BackgroundTransparency = 0.85,
			TextColor3 = colors.Text,
		}):Play()
	end)

	local closeXLeaveConn = closeX.MouseLeave:Connect(function()
		TweenService:Create(closeX, HOVER_INFO, {
			BackgroundTransparency = 1,
			TextColor3 = colors.TextMuted,
		}):Play()
	end)

	local closeXClickConn = closeX.MouseButton1Click:Connect(function()
		self:Hide()
	end)

	table.insert(self._connections, closeXHoverConn)
	table.insert(self._connections, closeXLeaveConn)
	table.insert(self._connections, closeXClickConn)

	-- Message body
	local bodyPadH = spacing.Lg or 16
	local bodyPadV = spacing.Md or 12
	local minBodyH = 20
	local bodyFrame = Instance.new("Frame")
	bodyFrame.Name                   = "Body"
	bodyFrame.Size                   = UDim2.new(1, 0, 0, 0)
	bodyFrame.Position               = UDim2.fromOffset(0, headerH)
	bodyFrame.AutomaticSize          = Enum.AutomaticSize.Y
	bodyFrame.BackgroundTransparency = 1
	bodyFrame.BorderSizePixel        = 0
	bodyFrame.ZIndex                 = card.ZIndex + 1
	bodyFrame.Parent                 = card

	local bodyPad = Instance.new("UIPadding")
	bodyPad.PaddingLeft   = UDim.new(0, bodyPadH)
	bodyPad.PaddingRight  = UDim.new(0, bodyPadH)
	bodyPad.PaddingTop    = UDim.new(0, bodyPadV)
	bodyPad.PaddingBottom = UDim.new(0, bodyPadV)
	bodyPad.Parent        = bodyFrame

	if message and #message > 0 then
		local msgLabel = Instance.new("TextLabel")
		msgLabel.Name                  = "Message"
		msgLabel.Size                  = UDim2.new(1, 0, 0, 0)
		msgLabel.AutomaticSize         = Enum.AutomaticSize.Y
		msgLabel.BackgroundTransparency = 1
		msgLabel.Text                  = message
		msgLabel.TextColor3            = colors.TextSub
		msgLabel.TextSize              = fontSizes.Base or 13
		msgLabel.Font                  = fonts.Body
		msgLabel.TextXAlignment        = Enum.TextXAlignment.Left
		msgLabel.TextYAlignment        = Enum.TextYAlignment.Top
		msgLabel.TextWrapped           = true
		msgLabel.ZIndex                = bodyFrame.ZIndex + 1
		msgLabel.Parent                = bodyFrame
		self._msgLabel = msgLabel
	end

	-- Button row
	local btnAreaH  = 60
	local btnDivY   = headerH  -- placeholder, computed dynamically
	-- We'll position the button row at the bottom

	local btnRow = Instance.new("Frame")
	btnRow.Name                   = "ButtonRow"
	btnRow.Size                   = UDim2.new(1, 0, 0, btnAreaH)
	btnRow.BackgroundTransparency = 1
	btnRow.BorderSizePixel        = 0
	btnRow.ZIndex                 = card.ZIndex + 1
	btnRow.Parent                 = card

	-- Button row divider
	local btnRowDiv = Instance.new("Frame")
	btnRowDiv.Name                   = "BtnRowDiv"
	btnRowDiv.Size                   = UDim2.new(1, 0, 0, 1)
	btnRowDiv.Position               = UDim2.fromOffset(0, 0)
	btnRowDiv.BackgroundColor3       = colors.Border
	btnRowDiv.BackgroundTransparency = theme.Transparency.Border or 0.07
	btnRowDiv.BorderSizePixel        = 0
	btnRowDiv.ZIndex                 = btnRow.ZIndex + 1
	btnRowDiv.Parent                 = btnRow

	local btnLayout = Instance.new("UIListLayout")
	btnLayout.FillDirection       = Enum.FillDirection.Horizontal
	btnLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	btnLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	btnLayout.Padding             = UDim.new(0, spacing.Sm or 8)
	btnLayout.Parent              = btnRow

	local btnPad = Instance.new("UIPadding")
	btnPad.PaddingRight  = UDim.new(0, spacing.Lg or 16)
	btnPad.PaddingTop    = UDim.new(0, spacing.Sm or 8)
	btnPad.PaddingBottom = UDim.new(0, spacing.Sm or 8)
	btnPad.Parent        = btnRow

	-- Build buttons (reversed so rightmost is last in layout)
	local btnCfg = (theme.Components and theme.Components.Button) or { Height = 34, PaddingH = 14 }

	for i, btnOpts in ipairs(buttons) do
		local bStyle     = btnOpts.Style or "secondary"
		local bLabel     = btnOpts.Label or "Button"
		local bCallback  = btnOpts.Callback

		-- Colors per style
		local bgColor, bgHover, bgPress, txtColor
		if bStyle == "primary" then
			bgColor  = colors.Accent
			bgHover  = colors.AccentHover or colors.Accent
			bgPress  = colors.AccentPress or colors.Accent
			txtColor = colors.White
		elseif bStyle == "danger" then
			bgColor  = colors.Danger
			bgHover  = colors.DangerHover or colors.Danger
			bgPress  = colors.DangerPress or colors.Danger
			txtColor = colors.White
		else
			-- secondary / ghost
			bgColor  = colors.Surface2
			bgHover  = colors.Surface3
			bgPress  = colors.Surface
			txtColor = colors.Text
		end

		local btn = Instance.new("TextButton")
		btn.Name                   = "Btn_" .. i
		btn.Size                   = UDim2.fromOffset(0, btnCfg.Height)
		btn.AutomaticSize          = Enum.AutomaticSize.X
		btn.BackgroundColor3       = bgColor
		btn.BackgroundTransparency = bStyle == "ghost" and 1 or 0
		btn.BorderSizePixel        = 0
		btn.Text                   = ""
		btn.AutoButtonColor        = false
		btn.ClipsDescendants       = false
		btn.LayoutOrder            = i
		btn.ZIndex                 = btnRow.ZIndex + 2
		btn.Parent                 = btnRow

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, radius.Button or 6)
		bCorner.Parent = btn

		if bStyle == "secondary" or bStyle == "ghost" then
			local bStroke = Instance.new("UIStroke")
			bStroke.Color        = colors.Border
			bStroke.Transparency = theme.Transparency.Border or 0.07
			bStroke.Thickness    = 1
			bStroke.Parent       = btn
		end

		local btnPadding = Instance.new("UIPadding")
		btnPadding.PaddingLeft  = UDim.new(0, btnCfg.PaddingH or 14)
		btnPadding.PaddingRight = UDim.new(0, btnCfg.PaddingH or 14)
		btnPadding.Parent       = btn

		local bLbl = Instance.new("TextLabel")
		bLbl.Name                  = "Label"
		bLbl.Size                  = UDim2.fromOffset(0, btnCfg.Height)
		bLbl.AutomaticSize         = Enum.AutomaticSize.X
		bLbl.BackgroundTransparency = 1
		bLbl.Text                  = bLabel
		bLbl.TextColor3            = txtColor
		bLbl.TextSize              = fontSizes.Base or 13
		bLbl.Font                  = fonts.SemiBold or fonts.Heading
		bLbl.ZIndex                = btn.ZIndex + 1
		bLbl.Parent                = btn

		-- Hover/press effects
		btn.MouseEnter:Connect(function()
			if bStyle == "ghost" then
				TweenService:Create(btn, HOVER_INFO, { BackgroundTransparency = 0.93 }):Play()
			else
				TweenService:Create(btn, HOVER_INFO, { BackgroundColor3 = bgHover }):Play()
			end
		end)

		btn.MouseLeave:Connect(function()
			if bStyle == "ghost" then
				TweenService:Create(btn, HOVER_INFO, { BackgroundTransparency = 1 }):Play()
			else
				TweenService:Create(btn, HOVER_INFO, { BackgroundColor3 = bgColor }):Play()
			end
		end)

		btn.MouseButton1Down:Connect(function()
			TweenService:Create(btn, HOVER_INFO, {
				BackgroundColor3 = bStyle == "ghost" and bgPress or bgPress,
			}):Play()
		end)

		btn.MouseButton1Up:Connect(function()
			TweenService:Create(btn, HOVER_INFO, {
				BackgroundColor3 = bgHover,
			}):Play()
		end)

		local btnClickConn = btn.MouseButton1Click:Connect(function()
			if bCallback then
				task.spawn(bCallback)
			end
			self:Hide()
		end)

		table.insert(self._connections, btnClickConn)
	end

	-- Close on backdrop click
	local backdropClickConn = backdrop.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local pos     = input.Position
			local cAbs    = card.AbsolutePosition
			local cSz     = card.AbsoluteSize
			local inCard  = pos.X >= cAbs.X and pos.X <= cAbs.X + cSz.X
				and pos.Y >= cAbs.Y and pos.Y <= cAbs.Y + cSz.Y
			if not inCard then
				self:Hide()
			end
		end
	end)

	table.insert(self._connections, backdropClickConn)

	-- Close on Escape
	local escapeConn = UserInputService.InputBegan:Connect(function(input, gp)
		if not self._visible then return end
		if input.KeyCode == Enum.KeyCode.Escape then
			self:Hide()
		end
	end)

	table.insert(self._connections, escapeConn)

	self._backdrop      = backdrop
	self._shadowHolder  = shadowHolder
	self._card          = card
	self._bodyFrame     = bodyFrame
	self._btnRow        = btnRow
	self._modalW        = modalW
	self._headerH       = headerH
	self._btnAreaH      = btnAreaH

	return self
end

--- Show the modal with animation
function Modal:Show()
	if self._visible then return end
	self._visible = true

	local colors  = self._theme.Colors
	local card    = self._card
	local backdrop = self._backdrop
	local holder  = self._shadowHolder

	-- Calculate final card height
	-- We need body content + header + button row
	-- Use AutomaticSize on body, so get measured height
	local bodyH = self._bodyFrame.AbsoluteSize.Y
	if bodyH < 20 then bodyH = 60 end  -- fallback min

	-- Padding + message + button row
	local totalH = self._headerH + bodyH + self._btnAreaH

	-- Size the shadow holder and card
	holder.Size = UDim2.fromOffset(self._modalW, totalH)
	card.Size   = UDim2.fromOffset(0, 0)

	-- Position the button row
	self._btnRow.Position = UDim2.fromOffset(0, self._headerH + bodyH)

	backdrop.Visible = true

	-- Animate backdrop
	TweenService:Create(backdrop, BACKDROP_INFO, {
		BackgroundTransparency = self._theme.Transparency.Overlay or 0.50,
	}):Play()

	-- Animate card scale-in
	card.Size = UDim2.fromOffset(math.floor(self._modalW * 0.92), math.floor(totalH * 0.92))

	TweenService:Create(card, OPEN_INFO, {
		Size = UDim2.fromOffset(self._modalW, totalH),
	}):Play()
end

--- Hide the modal with animation
function Modal:Hide()
	if not self._visible then return end
	self._visible = false

	local card    = self._card
	local backdrop = self._backdrop
	local totalH  = card.AbsoluteSize.Y

	TweenService:Create(backdrop, CLOSE_INFO, {
		BackgroundTransparency = 1,
	}):Play()

	TweenService:Create(card, CLOSE_INFO, {
		Size = UDim2.fromOffset(math.floor(self._modalW * 0.92), math.floor(totalH * 0.92)),
	}):Play()

	task.delay(0.24, function()
		if backdrop then
			backdrop.Visible = false
		end
		if card then
			card.Size = UDim2.fromOffset(0, 0)
		end
	end)
end

--- Destroy the modal entirely
function Modal:Destroy()
	if self._destroyed then return end
	self._destroyed = true

	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)

	if self._backdrop then
		self._backdrop:Destroy()
	end
end

return Modal
