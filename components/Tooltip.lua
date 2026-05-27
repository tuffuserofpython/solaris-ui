-- libui/components/Tooltip.lua
-- Floating tooltip component for LibUI

local TweenService = game:GetService("TweenService")

local Tooltip = {}

local HOVER_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

--- Attach a tooltip to a UI element
---@param element GuiObject The element to attach the tooltip to
---@param text string Tooltip text
---@param theme table Theme table
---@return table Tooltip controller with :Detach() method
function Tooltip.attach(element: GuiObject, text: string, theme: table)
	assert(element, "Tooltip.attach: element is nil")
	assert(text,    "Tooltip.attach: text is nil")

	local colors    = theme.Colors
	local fonts     = theme.Fonts
	local fontSizes = theme.FontSizes
	local spacing   = theme.Spacing
	local radius    = theme.Radius
	local compCfg   = theme.Components and theme.Components.Tooltip or { Delay = 0.5, Padding = 8, MaxWidth = 220 }

	local connections = {}
	local hoverTimer  = nil
	local tooltipGui  = nil
	local showing     = false

	-- Find the ScreenGui ancestor
	local function getScreenGui()
		local ancestor = element
		while ancestor do
			if ancestor:IsA("ScreenGui") or ancestor:IsA("BillboardGui") then
				return ancestor
			end
			ancestor = ancestor.Parent
		end
		return nil
	end

	local function destroyTooltip()
		if tooltipGui then
			local gui = tooltipGui
			tooltipGui = nil
			showing    = false
			-- Fade out
			local frame = gui:FindFirstChild("TooltipFrame")
			if frame then
				TweenService:Create(frame, HOVER_INFO, { BackgroundTransparency = 1 }):Play()
				local label = frame:FindFirstChild("Label")
				if label then
					TweenService:Create(label, HOVER_INFO, { TextTransparency = 1 }):Play()
				end
			end
			task.delay(0.15, function()
				if gui then
					gui:Destroy()
				end
			end)
		end
		if hoverTimer then
			task.cancel(hoverTimer)
			hoverTimer = nil
		end
	end

	local function showTooltip()
		if showing then return end
		showing = true

		local screenGui = getScreenGui()
		if not screenGui then return end

		-- Measure text size
		local padding   = compCfg.Padding or 8
		local maxWidth  = compCfg.MaxWidth or 220
		local fontSize  = fontSizes.Sm or 12
		local font      = fonts.Body

		local textSize = game:GetService("TextService"):GetTextSize(
			text,
			fontSize,
			font,
			Vector2.new(maxWidth - padding * 2, 100)
		)

		local tooltipW = math.min(textSize.X + padding * 2, maxWidth)
		local tooltipH = textSize.Y + padding * 2

		-- Create tooltip frame
		local frame = Instance.new("Frame")
		frame.Name                  = "TooltipFrame"
		frame.Size                  = UDim2.fromOffset(tooltipW, tooltipH)
		frame.BackgroundColor3      = colors.Surface3
		frame.BackgroundTransparency = 1  -- start transparent
		frame.BorderSizePixel       = 0
		frame.ZIndex                = 999

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, radius.Small or 4)
		corner.Parent = frame

		local stroke = Instance.new("UIStroke")
		stroke.Color        = colors.Border
		stroke.Transparency = theme.Transparency.Border or 0.07
		stroke.Thickness    = 1
		stroke.Parent       = frame

		local label = Instance.new("TextLabel")
		label.Name                  = "Label"
		label.Size                  = UDim2.new(1, -padding * 2, 1, -padding * 2)
		label.Position              = UDim2.fromOffset(padding, padding)
		label.BackgroundTransparency = 1
		label.Text                  = text
		label.TextColor3            = colors.TextSub
		label.TextTransparency      = 1  -- start transparent
		label.TextSize              = fontSize
		label.Font                  = font
		label.TextWrapped           = true
		label.TextXAlignment        = Enum.TextXAlignment.Left
		label.TextYAlignment        = Enum.TextYAlignment.Top
		label.ZIndex                = 1000
		label.Parent                = frame

		-- Position tooltip near the element
		local absPos  = element.AbsolutePosition
		local absSize = element.AbsoluteSize
		local screenSize = screenGui.AbsoluteSize or Vector2.new(1920, 1080)

		local tooltipX = absPos.X + absSize.X / 2 - tooltipW / 2
		local tooltipY = absPos.Y - tooltipH - 6

		-- If above screen, show below
		if tooltipY < 4 then
			tooltipY = absPos.Y + absSize.Y + 6
		end

		-- Clamp horizontal
		tooltipX = math.max(4, math.min(tooltipX, screenSize.X - tooltipW - 4))

		-- Create a holder ScreenGui layer or use existing
		local holder = Instance.new("ScreenGui")
		holder.Name              = "LibUI_Tooltip"
		holder.ResetOnSpawn      = false
		holder.IgnoreGuiInset    = true
		holder.DisplayOrder      = screenGui.DisplayOrder + 100
		holder.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling

		local ok, err = pcall(function()
			holder.Parent = game:GetService("CoreGui")
		end)
		if not ok then
			holder.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
		end

		frame.Position = UDim2.fromOffset(tooltipX, tooltipY)
		frame.Parent   = holder
		tooltipGui     = holder

		-- Fade in
		TweenService:Create(frame, HOVER_INFO, { BackgroundTransparency = 0 }):Play()
		TweenService:Create(label, HOVER_INFO, { TextTransparency = 0 }):Play()
	end

	-- Connect hover events
	local enterConn = element.MouseEnter:Connect(function()
		if hoverTimer then task.cancel(hoverTimer) end
		hoverTimer = task.delay(compCfg.Delay or 0.5, function()
			hoverTimer = nil
			showTooltip()
		end)
	end)

	local leaveConn = element.MouseLeave:Connect(function()
		if hoverTimer then
			task.cancel(hoverTimer)
			hoverTimer = nil
		end
		destroyTooltip()
	end)

	table.insert(connections, enterConn)
	table.insert(connections, leaveConn)

	-- Return controller
	local controller = {}

	function controller:Detach()
		destroyTooltip()
		for _, conn in ipairs(connections) do
			conn:Disconnect()
		end
		table.clear(connections)
	end

	function controller:UpdateText(newText: string)
		text = newText
	end

	return controller
end

return Tooltip
