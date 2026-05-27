-- libui/animations/Presets.lua
-- Animation preset definitions for LibUI

local Presets = {}

-- Fast hover/state transitions (0.15s)
Presets.Hover = {
	Time      = 0.15,
	Style     = Enum.EasingStyle.Quart,
	Direction = Enum.EasingDirection.Out,
}

-- Standard UI transitions (0.25s)
Presets.Normal = {
	Time      = 0.25,
	Style     = Enum.EasingStyle.Quart,
	Direction = Enum.EasingDirection.Out,
}

-- Slow/emphasis transitions (0.40s)
Presets.Slow = {
	Time      = 0.40,
	Style     = Enum.EasingStyle.Quart,
	Direction = Enum.EasingDirection.InOut,
}

-- Bounce/playful transitions (0.50s)
Presets.Bounce = {
	Time      = 0.50,
	Style     = Enum.EasingStyle.Back,
	Direction = Enum.EasingDirection.Out,
}

-- Spring/elastic transitions (0.60s)
Presets.Spring = {
	Time      = 0.60,
	Style     = Enum.EasingStyle.Elastic,
	Direction = Enum.EasingDirection.Out,
}

-- Intro/entrance animations (0.35s)
Presets.Intro = {
	Time      = 0.35,
	Style     = Enum.EasingStyle.Quint,
	Direction = Enum.EasingDirection.Out,
}

-- Instant (no animation)
Presets.Instant = {
	Time      = 0,
	Style     = Enum.EasingStyle.Linear,
	Direction = Enum.EasingDirection.Out,
}

-- Smooth linear transition
Presets.Linear = {
	Time      = 0.30,
	Style     = Enum.EasingStyle.Linear,
	Direction = Enum.EasingDirection.Out,
}

-- Sine ease for gentle transitions
Presets.Gentle = {
	Time      = 0.30,
	Style     = Enum.EasingStyle.Sine,
	Direction = Enum.EasingDirection.InOut,
}

-- Cubic for medium-weight transitions
Presets.Medium = {
	Time      = 0.20,
	Style     = Enum.EasingStyle.Cubic,
	Direction = Enum.EasingDirection.Out,
}

--- Apply a preset to TweenService
---@param instance Instance
---@param props table
---@param preset table
---@return TweenBase
function Presets.apply(instance: Instance, props: table, preset: table): TweenBase
	local TweenService = game:GetService("TweenService")
	local info = TweenInfo.new(
		preset.Time,
		preset.Style,
		preset.Direction
	)
	local tween = TweenService:Create(instance, info, props)
	tween:Play()
	return tween
end

--- Create a TweenInfo from a preset
---@param preset table
---@return TweenInfo
function Presets.toTweenInfo(preset: table): TweenInfo
	return TweenInfo.new(
		preset.Time,
		preset.Style,
		preset.Direction
	)
end

return Presets
