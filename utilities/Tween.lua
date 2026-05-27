-- libui/utilities/Tween.lua
-- Tween helper module for LibUI

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Tween = {}

-- Presets
Tween.FAST   = { Time = 0.15, Style = Enum.EasingStyle.Quart, Direction = Enum.EasingDirection.Out }
Tween.NORMAL = { Time = 0.25, Style = Enum.EasingStyle.Quart, Direction = Enum.EasingDirection.Out }
Tween.SLOW   = { Time = 0.40, Style = Enum.EasingStyle.Quart, Direction = Enum.EasingDirection.InOut }

-- Active tweens registry for cancel support
local activeTweens = {}

--- Play a tween on an instance
---@param instance Instance The instance to tween
---@param props table Property goals table
---@param duration number Duration in seconds
---@param style Enum.EasingStyle Easing style
---@param direction Enum.EasingDirection Easing direction
---@return TweenBase
function Tween.play(instance, props, duration, style, direction)
	assert(instance, "Tween.play: instance is nil")
	assert(props, "Tween.play: props is nil")

	duration  = duration  or Tween.NORMAL.Time
	style     = style     or Enum.EasingStyle.Quart
	direction = direction or Enum.EasingDirection.Out

	-- Cancel any existing tween on this instance for the same properties
	if activeTweens[instance] then
		local existingTween = activeTweens[instance]
		if existingTween and existingTween.PlaybackState ~= Enum.PlaybackState.Completed then
			existingTween:Cancel()
		end
	end

	local tweenInfo = TweenInfo.new(duration, style, direction)
	local tween = TweenService:Create(instance, tweenInfo, props)

	activeTweens[instance] = tween

	tween.Completed:Connect(function()
		if activeTweens[instance] == tween then
			activeTweens[instance] = nil
		end
	end)

	tween:Play()
	return tween
end

--- Play a tween using a preset table
---@param instance Instance
---@param props table
---@param preset table Preset from Tween.FAST/NORMAL/SLOW
---@return TweenBase
function Tween.playPreset(instance, props, preset)
	preset = preset or Tween.NORMAL
	return Tween.play(instance, props, preset.Time, preset.Style, preset.Direction)
end

--- Spring-based tween using RunService
---@param instance Instance
---@param props table { [propertyName] = targetValue }
---@param frequency number Spring frequency (default 5)
---@param damping number Damping ratio (default 1)
---@return table SpringTween object with :Cancel() method
function Tween.spring(instance, props, frequency, damping)
	frequency = frequency or 5
	damping   = damping   or 1

	local springTween = {
		_cancelled = false,
		_connections = {},
	}

	function springTween:Cancel()
		self._cancelled = true
		for _, conn in ipairs(self._connections) do
			conn:Disconnect()
		end
		table.clear(self._connections)
	end

	-- For each property, run a spring simulation
	for prop, target in pairs(props) do
		local currentValue = instance[prop]
		local velocity

		-- Initialize velocity based on type
		if typeof(currentValue) == "number" then
			velocity = 0
		elseif typeof(currentValue) == "Vector2" then
			velocity = Vector2.new(0, 0)
		elseif typeof(currentValue) == "Vector3" then
			velocity = Vector3.new(0, 0, 0)
		elseif typeof(currentValue) == "Color3" then
			velocity = Vector3.new(0, 0, 0)
		elseif typeof(currentValue) == "UDim2" then
			velocity = { x = Vector2.new(0, 0), y = Vector2.new(0, 0) }
		else
			-- Unsupported type, skip spring, just set directly
			instance[prop] = target
		end

		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if springTween._cancelled then
				conn:Disconnect()
				return
			end

			local stiffness = (2 * math.pi * frequency) ^ 2
			local dampingCoeff = 2 * damping * (2 * math.pi * frequency)

			if typeof(currentValue) == "number" then
				local force = stiffness * (target - currentValue) - dampingCoeff * velocity
				velocity = velocity + force * dt
				currentValue = currentValue + velocity * dt

				if math.abs(target - currentValue) < 0.001 and math.abs(velocity) < 0.001 then
					currentValue = target
					velocity = 0
					instance[prop] = currentValue
					conn:Disconnect()
					return
				end

				instance[prop] = currentValue

			elseif typeof(currentValue) == "Vector2" then
				local force = stiffness * (target - currentValue) - dampingCoeff * velocity
				velocity = velocity + force * dt
				currentValue = currentValue + velocity * dt

				if (target - currentValue).Magnitude < 0.001 and velocity.Magnitude < 0.001 then
					currentValue = target
					instance[prop] = currentValue
					conn:Disconnect()
					return
				end

				instance[prop] = currentValue

			elseif typeof(currentValue) == "Color3" then
				local cv = Vector3.new(currentValue.R, currentValue.G, currentValue.B)
				local tv = Vector3.new(target.R, target.G, target.B)
				local force = stiffness * (tv - cv) - dampingCoeff * velocity
				velocity = velocity + force * dt
				cv = cv + velocity * dt

				if (tv - cv).Magnitude < 0.001 then
					instance[prop] = target
					conn:Disconnect()
					return
				end

				instance[prop] = Color3.new(
					math.clamp(cv.X, 0, 1),
					math.clamp(cv.Y, 0, 1),
					math.clamp(cv.Z, 0, 1)
				)
			else
				conn:Disconnect()
			end
		end)

		table.insert(springTween._connections, conn)
	end

	return springTween
end

--- Cancel a tween
---@param tween TweenBase|table
function Tween.cancel(tween)
	if tween then
		if typeof(tween) == "Instance" then
			tween:Cancel()
		elseif type(tween) == "table" and tween.Cancel then
			tween:Cancel()
		end
	end
end

--- Tween a number value and call callback each step
---@param from number
---@param to number
---@param duration number
---@param callback function(value: number)
---@param style Enum.EasingStyle
---@param direction Enum.EasingDirection
---@param onComplete function?
function Tween.tweenValue(from, to, duration, callback, style, direction, onComplete)
	style = style or Enum.EasingStyle.Quart
	direction = direction or Enum.EasingDirection.Out

	local numberValue = Instance.new("NumberValue")
	numberValue.Value = from

	local tweenInfo = TweenInfo.new(duration, style, direction)
	local tween = TweenService:Create(numberValue, tweenInfo, { Value = to })

	numberValue.Changed:Connect(function(val)
		callback(val)
	end)

	tween.Completed:Connect(function()
		callback(to)
		if onComplete then onComplete() end
		numberValue:Destroy()
	end)

	tween:Play()
	return tween
end

return Tween
