-- libui/utilities/Utils.lua
-- Utility functions for LibUI

local Utils = {}

local HttpService = game:GetService("HttpService")

--- Round a number to given decimal places
---@param n number
---@param decimals number
---@return number
function Utils.round(n: number, decimals: number?): number
	decimals = decimals or 0
	local factor = 10 ^ decimals
	return math.floor(n * factor + 0.5) / factor
end

--- Clamp a value between min and max
---@param v number
---@param min number
---@param max number
---@return number
function Utils.clamp(v: number, min: number, max: number): number
	return math.max(min, math.min(max, v))
end

--- Linear interpolation between two numbers
---@param a number
---@param b number
---@param t number 0..1
---@return number
function Utils.lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

--- Interpolate between two Color3 values
---@param c1 Color3
---@param c2 Color3
---@param t number 0..1
---@return Color3
function Utils.lerpColor(c1: Color3, c2: Color3, t: number): Color3
	return Color3.new(
		Utils.lerp(c1.R, c2.R, t),
		Utils.lerp(c1.G, c2.G, t),
		Utils.lerp(c1.B, c2.B, t)
	)
end

--- Format a number with comma separators
---@param n number
---@return string
function Utils.formatNumber(n: number): string
	local s = tostring(math.floor(n))
	local result = ""
	local len = #s
	for i = 1, len do
		if i > 1 and (len - i + 1) % 3 == 0 then
			result = result .. ","
		end
		result = result .. s:sub(i, i)
	end
	-- Handle decimal part
	local dec = tostring(n):match("%.%d+$")
	if dec then
		result = result .. dec
	end
	return result
end

--- Deep copy a table
---@param t table
---@return table
function Utils.deepCopy(t: table): table
	if type(t) ~= "table" then return t end
	local copy = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			copy[k] = Utils.deepCopy(v)
		else
			copy[k] = v
		end
	end
	return setmetatable(copy, getmetatable(t))
end

--- Deep merge two tables (override takes priority)
---@param base table
---@param override table
---@return table
function Utils.merge(base: table, override: table): table
	local result = Utils.deepCopy(base)
	for k, v in pairs(override) do
		if type(v) == "table" and type(result[k]) == "table" then
			result[k] = Utils.merge(result[k], v)
		else
			result[k] = v
		end
	end
	return result
end

--- Generate a unique string ID using HttpService
---@return string
function Utils.uid(): string
	local ok, result = pcall(function()
		return HttpService:GenerateGUID(false):gsub("-", ""):lower()
	end)
	if ok then
		return result
	end
	-- Fallback
	return tostring(math.random(100000000, 999999999)) .. tostring(tick()):gsub("%.", "")
end

--- Generate a short random alphanumeric ID (8 chars)
---@return string
function Utils.makeUID(): string
	local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	local id = ""
	for _ = 1, 8 do
		local idx = math.random(1, #chars)
		id = id .. chars:sub(idx, idx)
	end
	return id
end

--- Convert a hex color string to Color3
---@param hex string "#RRGGBB" or "RRGGBB"
---@return Color3
function Utils.hexToColor(hex: string): Color3
	hex = hex:gsub("#", "")
	local r = tonumber(hex:sub(1, 2), 16) or 0
	local g = tonumber(hex:sub(3, 4), 16) or 0
	local b = tonumber(hex:sub(5, 6), 16) or 0
	return Color3.fromRGB(r, g, b)
end

--- Convert Color3 to hex string
---@param color Color3
---@return string "#RRGGBB"
function Utils.colorToHex(color: Color3): string
	local r = math.floor(color.R * 255 + 0.5)
	local g = math.floor(color.G * 255 + 0.5)
	local b = math.floor(color.B * 255 + 0.5)
	return string.format("#%02X%02X%02X", r, g, b)
end

--- Check if a value is in a table
---@param t table
---@param value any
---@return boolean
function Utils.contains(t: table, value: any): boolean
	for _, v in ipairs(t) do
		if v == value then
			return true
		end
	end
	return false
end

--- Get table keys as an array
---@param t table
---@return table
function Utils.keys(t: table): table
	local result = {}
	for k in pairs(t) do
		table.insert(result, k)
	end
	return result
end

--- Get table values as an array
---@param t table
---@return table
function Utils.values(t: table): table
	local result = {}
	for _, v in pairs(t) do
		table.insert(result, v)
	end
	return result
end

--- Create a debounced version of a function
---@param fn function
---@param delay number
---@return function
function Utils.debounce(fn: (...any) -> (), delay: number): (...any) -> ()
	local timer = nil
	return function(...)
		local args = { ... }
		if timer then
			task.cancel(timer)
		end
		timer = task.delay(delay, function()
			timer = nil
			fn(table.unpack(args))
		end)
	end
end

--- Create a throttled version of a function
---@param fn function
---@param interval number
---@return function
function Utils.throttle(fn: (...any) -> (), interval: number): (...any) -> ()
	local lastCall = 0
	return function(...)
		local now = tick()
		if now - lastCall >= interval then
			lastCall = now
			fn(...)
		end
	end
end

--- Safely call a function, catching errors
---@param fn function
---@param ... any
---@return boolean, any
function Utils.safeCall(fn: (...any) -> (), ...): (boolean, any)
	return pcall(fn, ...)
end

--- Convert a UDim2 to pixel coordinates given a container size
---@param udim UDim2
---@param containerSize Vector2
---@return Vector2
function Utils.udim2ToPixel(udim: UDim2, containerSize: Vector2): Vector2
	return Vector2.new(
		udim.X.Scale * containerSize.X + udim.X.Offset,
		udim.Y.Scale * containerSize.Y + udim.Y.Offset
	)
end

--- Pad a string to a given length
---@param s string
---@param length number
---@param char string? character to pad with (default " ")
---@return string
function Utils.padStart(s: string, length: number, char: string?): string
	char = char or " "
	while #s < length do
		s = char .. s
	end
	return s
end

return Utils
