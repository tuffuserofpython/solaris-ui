-- libui/utilities/Config.lua
-- Config persistence using executor writefile/readfile APIs

local HttpService = game:GetService("HttpService")

local Config = {}
Config.__index = Config

-- Check if executor file APIs are available
local function hasFileAccess(): boolean
	return type(writefile) == "function" and type(readfile) == "function"
end

local function fileExists(path: string): boolean
	if type(isfile) == "function" then
		return isfile(path)
	end
	-- Fallback: try to read the file
	local ok = pcall(readfile, path)
	return ok
end

--- Create a new config object
---@param name string Config file name (will be saved as "libui_<name>.json")
---@return table Config object
function Config.new(name: string)
	assert(type(name) == "string" and #name > 0, "Config.new: name must be a non-empty string")

	local self = setmetatable({}, Config)
	self._name     = name
	self._filename = "libui_" .. name .. ".json"
	self._data     = {}
	self._loaded   = false

	-- Auto-load on creation
	self:Load()

	return self
end

--- Get a config value, returning default if not set
---@param key string
---@param default any
---@return any
function Config:Get(key: string, default: any): any
	if not self._loaded then
		self:Load()
	end

	local value = self._data[key]
	if value == nil then
		return default
	end
	return value
end

--- Set a config value
---@param key string
---@param value any Must be JSON-serializable
function Config:Set(key: string, value: any)
	self._data[key] = value
end

--- Save config to file
function Config:Save()
	if not hasFileAccess() then
		-- No file access available, skip silently
		return false
	end

	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(self._data)
	end)

	if not ok then
		warn("[LibUI Config] Failed to encode config '" .. self._name .. "': " .. tostring(encoded))
		return false
	end

	local writeOk, err = pcall(writefile, self._filename, encoded)
	if not writeOk then
		warn("[LibUI Config] Failed to write config '" .. self._name .. "': " .. tostring(err))
		return false
	end

	return true
end

--- Load config from file
function Config:Load()
	self._loaded = true

	if not hasFileAccess() then
		return false
	end

	if not fileExists(self._filename) then
		self._data = {}
		return false
	end

	local ok, content = pcall(readfile, self._filename)
	if not ok or type(content) ~= "string" or #content == 0 then
		self._data = {}
		return false
	end

	local decodeOk, decoded = pcall(function()
		return HttpService:JSONDecode(content)
	end)

	if not decodeOk or type(decoded) ~= "table" then
		warn("[LibUI Config] Failed to decode config '" .. self._name .. "', resetting.")
		self._data = {}
		return false
	end

	self._data = decoded
	return true
end

--- Reset config to empty
function Config:Reset()
	self._data = {}

	if hasFileAccess() and fileExists(self._filename) then
		local ok, err = pcall(writefile, self._filename, "{}")
		if not ok then
			warn("[LibUI Config] Failed to reset config '" .. self._name .. "': " .. tostring(err))
		end
	end
end

--- Get all config data as a table
---@return table
function Config:GetAll(): table
	return self._data
end

--- Set multiple config values at once
---@param t table
function Config:SetAll(t: table)
	for k, v in pairs(t) do
		self._data[k] = v
	end
end

--- Check if a key exists
---@param key string
---@return boolean
function Config:Has(key: string): boolean
	return self._data[key] ~= nil
end

--- Remove a key
---@param key string
function Config:Remove(key: string)
	self._data[key] = nil
end

return Config
