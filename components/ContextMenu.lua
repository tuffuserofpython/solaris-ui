-- libui/components/ContextMenu.lua
-- Context menu component for LibUI

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ContextMenu = {}
ContextMenu.__index = ContextMenu

local OPEN_INFO  = TweenInfo.new(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local CLOSE_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
local HOVER_INFO = TweenInfo.new(0.10, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

--- Create a new context menu
---@param screenGui ScreenGui
---@param options table { Items = { {Label, Icon, Callback, Separator} } }
---@param theme table
---@return table ContextMenu object
function ContextMenu.new(screenGui: ScreenGui, options: table, theme: table)
	assert(screenGui, "ContextMenu.new: screenGui is nil")

	local colors    = theme.Colors
	local fonts     = theme.Fonts
	local fontSizes = theme.FontSizes
	local radius    = theme.Radius

	local self        = setmetatable({}, ContextMenu)
	self._theme       = theme
	self._connections = {}
	self._destroyed   = false
	self._items       = options.Items or {}
	self._screenGui   = screenGui
	self._frame       = nil
	self._visible     = false
	self._focusIndex  = 1

	return self
end

--- Show the context menu at position
---@param x number Absolute X position
---@param y number Absolute Y position
function ContextMenu:Show(x: number, y: number)
	if self._visible then
		self:_destroyFrame()
	end

	self._visible  = true
	self._focusIndex = 1

	local colors    = self._theme.Colors
	local fonts     = self._theme.Fonts
	local fontSizes = self._theme.FontSizes
	local radius    = self._theme.Radius
	local shadows   = self._theme.Shadows

	local itemH    = 32
	local sepH     = 9
	local menuW    = 180
	local padV     = 5

	-- Calculate total height
	local totalH = padV * 2
	for _, item in ipairs(self._items) do
		if item.Separator then
			totalH = totalH + sepH
		else
			totalH = totalH + itemH
		end
	end

	-- Clamp to screen
	local screenSize = self._screenGui.AbsoluteSize
	if x + menuW > screenSize.X - 4 then
		x = screenSize.X - menuW - 4
	end
	if y + totalH > screenSize.Y - 4 then
		y = screenSize.Y - totalH - 4
	end

	-- Shadow
	local shadowH = Instance.new("Frame")
	shadowH.Name                   = "ContextShadow"
	shadowH.Size                   = UDim2.fromOffset(menuW, totalH)
	shadowH.Position               = UDim2.fromOffset(x, y)
	shadowH.BackgroundTransparency = 1
	shadowH.ZIndex                 = 400
	shadowH.Parent                 = self._screenGui

	local shadowImg = Instance.new("ImageLabel")
	shadowImg.Size             = shadows.Popup.Size
	shadowImg.Position         = shadows.Popup.Position
	shadowImg.BackgroundTransparency = 1
	shadowImg.Image            = shadows.AssetId
	shadowImg.ImageColor3      = shadows.Popup.Color
	shadowImg.ImageTransparency = shadows.Popup.Transparency
	shadowImg.ScaleType        = Enum.ScaleType.Slice
	shadowImg.SliceCenter      = shadows.SliceRect
	shadowImg.ZIndex           = 400
	shadowImg.Parent           = shadowH

	-- Menu frame
	local frame = Instance.new("Frame")
	frame.Name                   = "ContextMenu"
	frame.Size                   = UDim2.fromOffset(menuW, 0)  -- start collapsed
	frame.Position               = UDim2.fromScale(0, 0)
	frame.BackgroundColor3       = colors.Surface2
	frame.BackgroundTransparency = 0
	frame.BorderSizePixel        = 0
	frame.ClipsDescendants       = true
	frame.ZIndex                 = 401
	frame.Parent                 = shadowH

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, radius.Card or 8)
	frameCorner.Parent = frame

	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color        = colors.Border
	frameStroke.Transparency = theme.Transparency.Border or 0.07
	frameStroke.Thickness    = 1
	frameStroke.Parent       = frame

	-- Build items
	local itemFrames = {}
	local curY       = padV

	for i, item in ipairs(self._items) do
		if item.Separator then
			-- Separator line
			local sep = Instance.new("Frame")
			sep.Name             = "Separator_" .. i
			sep.Size             = UDim2.new(1, -16, 0, 1)
			sep.Position         = UDim2.fromOffset(8, curY + (sepH - 1) / 2)
			sep.BackgroundColor3 = colors.Border
			sep.BackgroundTransparency = theme.Transparency.Border or 0.07
			sep.BorderSizePixel  = 0
			sep.ZIndex           = frame.ZIndex + 1
			sep.Parent           = frame
			curY = curY + sepH
		else
			local itemBtn = Instance.new("TextButton")
			itemBtn.Name             = "Item_" .. i
			itemBtn.Size             = UDim2.new(1, -8, 0, itemH)
			itemBtn.Position         = UDim2.fromOffset(4, curY)
			itemBtn.BackgroundColor3 = colors.Surface3
			itemBtn.BackgroundTransparency = 1
			itemBtn.BorderSizePixel  = 0
			itemBtn.Text             = ""
			itemBtn.AutoButtonColor  = false
			itemBtn.ZIndex           = frame.ZIndex + 1
			itemBtn.Parent           = frame

			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = UDim.new(0, radius.Small or 4)
			itemCorner.Parent = itemBtn

			-- Content layout
			local contentLayout = Instance.new("UIListLayout")
			contentLayout.FillDirection       = Enum.FillDirection.Horizontal
			contentLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
			contentLayout.Padding             = UDim.new(0, 8)
			contentLayout.Parent              = itemBtn

			local cPad = Instance.new("UIPadding")
			cPad.PaddingLeft = UDim.new(0, 12)
			cPad.Parent      = itemBtn

			-- Icon (optional)
			if item.Icon and #item.Icon > 0 then
				local icon = Instance.new("ImageLabel")
				icon.Name                   = "Icon"
				icon.Size                   = UDim2.fromOffset(14, 14)
				icon.BackgroundTransparency = 1
				icon.Image                  = item.Icon
				icon.ImageColor3            = colors.TextSub
				icon.ZIndex                 = itemBtn.ZIndex + 1
				icon.Parent                 = itemBtn
			end

			local label = Instance.new("TextLabel")
			label.Name                  = "Label"
			label.Size                  = UDim2.fromOffset(0, itemH)
			label.AutomaticSize         = Enum.AutomaticSize.X
			label.BackgroundTransparency = 1
			label.Text                  = item.Label or ""
			label.TextColor3            = item.Danger and colors.Danger or colors.Text
			label.TextSize              = fontSizes.Base or 13
			label.Font                  = fonts.Body
			label.TextXAlignment        = Enum.TextXAlignment.Left
			label.ZIndex                = itemBtn.ZIndex + 1
			label.Parent                = itemBtn

			-- Hover effects
			itemBtn.MouseEnter:Connect(function()
				TweenService:Create(itemBtn, HOVER_INFO, {
					BackgroundColor3       = item.Danger and colors.DangerSoft or colors.Surface3,
					BackgroundTransparency = item.Danger and (theme.Transparency.DangerSoft or 0.15) or 0.90,
				}):Play()
				TweenService:Create(label, HOVER_INFO, {
					TextColor3 = item.Danger and colors.Danger or colors.Text,
				}):Play()
			end)

			itemBtn.MouseLeave:Connect(function()
				TweenService:Create(itemBtn, HOVER_INFO, { BackgroundTransparency = 1 }):Play()
				TweenService:Create(label, HOVER_INFO, {
					TextColor3 = item.Danger and colors.Danger or colors.Text,
				}):Play()
			end)

			itemBtn.MouseButton1Click:Connect(function()
				self:Hide()
				if item.Callback then
					task.spawn(item.Callback)
				end
			end)

			table.insert(itemFrames, itemBtn)
			curY = curY + itemH
		end
	end

	self._frame       = shadowH
	self._itemFrames  = itemFrames

	-- Animate open
	TweenService:Create(frame, OPEN_INFO, {
		Size = UDim2.fromOffset(menuW, totalH),
	}):Play()

	-- Keyboard navigation
	local navConn
	navConn = UserInputService.InputBegan:Connect(function(input, gp)
		if not self._visible then
			navConn:Disconnect()
			return
		end

		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape then
				self:Hide()
				navConn:Disconnect()
			elseif input.KeyCode == Enum.KeyCode.Down then
				self._focusIndex = math.min(self._focusIndex + 1, #itemFrames)
				self:_highlightItem(self._focusIndex)
			elseif input.KeyCode == Enum.KeyCode.Up then
				self._focusIndex = math.max(self._focusIndex - 1, 1)
				self:_highlightItem(self._focusIndex)
			elseif input.KeyCode == Enum.KeyCode.Return then
				local focused = itemFrames[self._focusIndex]
				if focused then
					focused.MouseButton1Click:Fire()
				end
				navConn:Disconnect()
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- Close on outside click
			local pos    = input.Position
			local fAbs   = frame.AbsolutePosition
			local fSz    = frame.AbsoluteSize

			local inFrame = pos.X >= fAbs.X and pos.X <= fAbs.X + fSz.X
				and pos.Y >= fAbs.Y and pos.Y <= fAbs.Y + fSz.Y

			if not inFrame then
				self:Hide()
				navConn:Disconnect()
			end
		end
	end)

	table.insert(self._connections, navConn)
end

--- Highlight an item for keyboard navigation
---@param index number
function ContextMenu:_highlightItem(index: number)
	for i, item in ipairs(self._itemFrames) do
		local isActive = i == index
		TweenService:Create(item, HOVER_INFO, {
			BackgroundColor3       = isActive and self._theme.Colors.Surface3 or self._theme.Colors.Surface3,
			BackgroundTransparency = isActive and 0.90 or 1,
		}):Play()
	end
end

--- Hide/close the context menu
function ContextMenu:Hide()
	if not self._visible then return end
	self._visible = false
	self:_destroyFrame()
end

--- Internal: destroy the frame
function ContextMenu:_destroyFrame()
	if self._frame then
		local f = self._frame
		self._frame = nil
		-- Fade out
		local menuFrame = f:FindFirstChild("ContextMenu")
		if menuFrame then
			TweenService:Create(menuFrame, CLOSE_INFO, { BackgroundTransparency = 1 }):Play()
		end
		task.delay(0.17, function()
			if f and f.Parent then f:Destroy() end
		end)
	end
end

--- Destroy the context menu component entirely
function ContextMenu:Destroy()
	if self._destroyed then return end
	self._destroyed = true

	self:Hide()

	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)
end

return ContextMenu
