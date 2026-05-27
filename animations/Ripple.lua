-- libui/animations/Ripple.lua
-- Ripple click effect module for LibUI

local TweenService = game:GetService("TweenService")

local Ripple = {}

local RIPPLE_DURATION = 0.55
local RIPPLE_FADE_START = 0.25

--- Play a ripple effect on a parent frame at the given position
---@param parent Frame The parent frame to attach the ripple to
---@param x number X position in absolute pixels (from MouseButton1Click)
---@param y number Y position in absolute pixels
---@param color Color3? Color of the ripple (defaults to white)
---@param opacity number? Starting opacity (defaults to 0.6)
function Ripple.play(parent: Frame, x: number, y: number, color: Color3?, opacity: number?)
	color   = color   or Color3.fromRGB(255, 255, 255)
	opacity = opacity or 0.6

	-- Convert absolute position to relative position within parent
	local parentAbsPos  = parent.AbsolutePosition
	local parentAbsSize = parent.AbsoluteSize

	local relX = x - parentAbsPos.X
	local relY = y - parentAbsPos.Y

	-- Calculate max ripple size (cover the full element)
	local maxDim = math.max(parentAbsSize.X, parentAbsSize.Y)
	local rippleSize = maxDim * 2.5

	-- Create ripple container (clipped to parent)
	local clipFrame = Instance.new("Frame")
	clipFrame.Name             = "RippleClip"
	clipFrame.Size             = UDim2.fromScale(1, 1)
	clipFrame.Position         = UDim2.fromScale(0, 0)
	clipFrame.BackgroundTransparency = 1
	clipFrame.ClipsDescendants = true
	clipFrame.ZIndex           = parent.ZIndex + 5
	clipFrame.Parent           = parent

	-- Create the ripple circle
	local ripple = Instance.new("Frame")
	ripple.Name                  = "Ripple"
	ripple.BackgroundColor3      = color
	ripple.BackgroundTransparency = 1 - opacity
	ripple.BorderSizePixel       = 0
	ripple.Size                  = UDim2.fromOffset(0, 0)
	ripple.Position              = UDim2.fromOffset(relX, relY)
	ripple.AnchorPoint           = Vector2.new(0.5, 0.5)
	ripple.ZIndex                = parent.ZIndex + 6
	ripple.Parent                = clipFrame

	-- Round the ripple
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent       = ripple

	-- Phase 1: Expand the ripple
	local expandInfo = TweenInfo.new(
		RIPPLE_DURATION,
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.Out
	)

	local expandTween = TweenService:Create(ripple, expandInfo, {
		Size = UDim2.fromOffset(rippleSize, rippleSize),
	})

	-- Phase 2: Fade out (starts slightly after expand begins)
	local fadeInfo = TweenInfo.new(
		RIPPLE_DURATION - RIPPLE_FADE_START,
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.In
	)

	local fadeTween = TweenService:Create(ripple, fadeInfo, {
		BackgroundTransparency = 1,
	})

	-- Play expand
	expandTween:Play()

	-- Delay fade start
	task.delay(RIPPLE_FADE_START, function()
		fadeTween:Play()
	end)

	-- Cleanup after animation completes
	expandTween.Completed:Connect(function()
		clipFrame:Destroy()
	end)
end

--- Play a subtle ripple for secondary/ghost buttons
---@param parent Frame
---@param x number
---@param y number
---@param color Color3?
function Ripple.playSoft(parent: Frame, x: number, y: number, color: Color3?)
	Ripple.play(parent, x, y, color, 0.3)
end

--- Play a strong ripple for primary buttons
---@param parent Frame
---@param x number
---@param y number
---@param color Color3?
function Ripple.playStrong(parent: Frame, x: number, y: number, color: Color3?)
	Ripple.play(parent, x, y, color, 0.45)
end

return Ripple
