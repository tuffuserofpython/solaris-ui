-- libui/init.lua
-- Main entry point for the libui library
-- Usage:
--   local libui = require(path_to_libui)
--   libui:Init({ Theme = "Default" })
--   local win = libui:Window({ Title = "My Window" })

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")

-- ============================================================
-- Module require helper
-- Uses script-relative requires where possible;
-- falls back to loadstring paths for executor environments.
-- ============================================================

local LIBUI_ROOT = script  -- reference to the libui module root

local function req(path)
	-- path is relative: e.g. "themes.Default"
	local parts  = path:split(".")
	local cursor = LIBUI_ROOT
	for _, part in ipairs(parts) do
		local child = cursor:FindFirstChild(part)
		if not child then
			error("[libui] Cannot find module: " .. path .. " (missing: " .. part .. ")", 2)
		end
		cursor = child
	end
	return require(cursor)
end

-- ============================================================
-- Lazy-load cache
-- ============================================================
local _cache = {}

local function load(path)
	if not _cache[path] then
		_cache[path] = req(path)
	end
	return _cache[path]
end

-- ============================================================
-- libui public API table
-- ============================================================
local libui = {}
libui.__index = libui

-- Internal state
libui._initialized    = false
libui._theme          = nil
libui._screenGui      = nil
libui._notifManager   = nil
libui._windows        = {}
libui._configs        = {}

-- ============================================================
-- Init
-- ============================================================

--- Initialize the library
---@param options table? { Theme, ScreenGui, DisplayOrder }
function libui:Init(options: table?)
	if self._initialized then return self end

	options = options or {}

	-- Load theme
	local themeName = options.Theme or "Default"
	local themeModule = "themes." .. themeName
	local ok, themeResult = pcall(load, themeModule)
	if not ok then
		-- Fallback to Default if theme not found
		warn("[libui] Theme '" .. themeName .. "' not found, using Default")
		themeResult = load("themes.Default")
	end
	self._theme = themeResult

	-- Create or reuse ScreenGui
	if options.ScreenGui then
		self._screenGui = options.ScreenGui
	else
		local localPlayer = Players.LocalPlayer
		if not localPlayer then
			localPlayer = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
		end

		local playerGui = localPlayer:WaitForChild("PlayerGui")

		-- Remove old instance if re-initializing
		local existing = playerGui:FindFirstChild("LibUI_Root")
		if existing then existing:Destroy() end

		local sg = Instance.new("ScreenGui")
		sg.Name               = "LibUI_Root"
		sg.ResetOnSpawn       = false
		sg.IgnoreGuiInset     = true
		sg.DisplayOrder       = options.DisplayOrder or 100
		sg.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
		sg.Parent             = playerGui
		self._screenGui       = sg
	end

	-- Notification manager
	local Notification = load("components.Notification")
	self._notifManager = Notification.new(self._screenGui, self._theme)

	self._initialized = true
	return self
end

-- ============================================================
-- Window factory
-- ============================================================

--- Create and show a new window
---@param options table { Title, Subtitle, Size, Position, MinSize, Resizable, Closable, Minimizable }
---@return table Window object
function libui:Window(options: table)
	if not self._initialized then self:Init() end

	local Window = load("components.Window")
	local sizeOpts = options.Size
	local sizeVec  = nil
	if sizeOpts then
		if type(sizeOpts) == "table" then
			sizeVec = sizeOpts  -- pass as-is { X = w, Y = h }
		end
	end

	local winOptions = {
		Title       = options.Title       or "Window",
		Subtitle    = options.Subtitle    or "",
		Size        = sizeVec,
		Position    = options.Position,
		MinSize     = options.MinSize,
		Resizable   = options.Resizable,
		Closable    = options.Closable,
		Minimizable = options.Minimizable,
	}

	local win = Window.new(self._screenGui, winOptions, self._theme)
	table.insert(self._windows, win)

	-- Show immediately if not deferred
	task.defer(function()
		win:Show()
	end)

	return win
end

-- ============================================================
-- Notifications
-- ============================================================

--- Show a notification
---@param options table { Title, Message, Type, Duration }
function libui:Notify(options: table)
	if not self._initialized then self:Init() end
	if not self._notifManager then
		warn("[libui] Notification manager not initialized")
		return
	end
	self._notifManager:Notify(options)
end

-- ============================================================
-- Theme management
-- ============================================================

--- Set the active theme
---@param themeName string "Default", "Light", or "Midnight"
function libui:SetTheme(themeName: string)
	local ok, themeResult = pcall(load, "themes." .. themeName)
	if not ok then
		warn("[libui] Theme '" .. themeName .. "' not found")
		return
	end
	self._theme = themeResult

	-- Re-create notification manager with new theme
	if self._notifManager then
		self._notifManager:Destroy()
	end
	if self._screenGui then
		local Notification = load("components.Notification")
		self._notifManager = Notification.new(self._screenGui, self._theme)
	end
end

--- Get the current active theme table
---@return table
function libui:GetTheme(): table
	if not self._theme then
		self._theme = load("themes.Default")
	end
	return self._theme
end

-- ============================================================
-- Config helpers
-- ============================================================

--- Create or retrieve a named config
---@param name string
---@return table Config object
function libui:GetConfig(name: string)
	if not self._configs[name] then
		local Config = load("utilities.Config")
		self._configs[name] = Config.new(name)
	end
	return self._configs[name]
end

--- Save all configs
function libui:SaveConfig()
	for _, cfg in pairs(self._configs) do
		cfg:Save()
	end
end

--- Load all configs
function libui:LoadConfig()
	for _, cfg in pairs(self._configs) do
		cfg:Load()
	end
end

-- ============================================================
-- Component factories (convenience wrappers)
-- ============================================================

--- Create a standalone Modal
---@param options table { Title, Message, Buttons, Width }
---@return table Modal object
function libui:Modal(options: table)
	if not self._initialized then self:Init() end
	local Modal = load("components.Modal")
	return Modal.new(self._screenGui, options, self._theme)
end

--- Create a standalone ContextMenu
---@param options table { Items }
---@return table ContextMenu object
function libui:ContextMenu(options: table)
	if not self._initialized then self:Init() end
	local ContextMenu = load("components.ContextMenu")
	return ContextMenu.new(self._screenGui, options, self._theme)
end

--- Attach a Tooltip to an element
---@param element GuiObject
---@param text string
---@return table Tooltip controller
function libui:Tooltip(element: GuiObject, text: string)
	if not self._initialized then self:Init() end
	local Tooltip = load("components.Tooltip")
	return Tooltip.attach(element, text, self._theme)
end

-- ============================================================
-- Utility access
-- ============================================================

--- Get the Utils module
---@return table
function libui:Utils()
	return load("utilities.Utils")
end

--- Get the Tween module
---@return table
function libui:Tween()
	return load("utilities.Tween")
end

--- Get the Signal constructor
---@return table
function libui:Signal()
	return load("utilities.Signal")
end

--- Get the animation Presets table
---@return table
function libui:Presets()
	return load("animations.Presets")
end

-- ============================================================
-- Cleanup
-- ============================================================

--- Destroy all libui state and GUI
function libui:Destroy()
	for _, win in ipairs(self._windows) do
		if win and win.Destroy then
			pcall(function() win:Destroy() end)
		end
	end
	table.clear(self._windows)

	for _, cfg in pairs(self._configs) do
		if cfg and cfg.Save then
			pcall(function() cfg:Save() end)
		end
	end
	table.clear(self._configs)

	if self._notifManager then
		pcall(function() self._notifManager:Destroy() end)
		self._notifManager = nil
	end

	if self._screenGui and self._screenGui.Parent then
		self._screenGui:Destroy()
		self._screenGui = nil
	end

	self._initialized = false
	self._theme       = nil
	table.clear(_cache)
end

return libui
