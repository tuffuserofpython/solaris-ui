-- libui/examples/Demo.lua
-- Complete demo showcasing every component in libui
-- Run this script inside a LocalScript in Roblox Studio or an executor

-- ============================================================
-- Bootstrap: locate libui
-- ============================================================

local libui
do
	-- Try normal require path first (Studio ModuleScript sibling)
	local ok, result = pcall(function()
		return require(script.Parent.Parent)  -- libui/init.lua from libui/examples/Demo.lua
	end)
	if ok then
		libui = result
	else
		-- Executor fallback: assume libui is already loaded as a global or loadstring
		libui = _G.libui or error("[Demo] Could not locate libui. Please require it first.")
	end
end

-- ============================================================
-- Initialize library with Default dark theme
-- ============================================================
libui:Init({ Theme = "Default" })

local theme = libui:GetTheme()
local Ripple = require(script.Parent.Parent.animations.Ripple)

-- ============================================================
-- Create the main window
-- ============================================================
local win = libui:Window({
	Title       = "libui Demo",
	Subtitle    = "v1.0 — Premium UI Library",
	Size        = { X = 600, Y = 460 },
})

-- ============================================================
-- Tab 1: Components
-- ============================================================
local tabComponents = win:AddTab({ Label = "Components" })

-- ---- Section: Interactive Controls ----
local sControls = tabComponents:AddSection({
	Title       = "Interactive Controls",
	Description = "Core input components",
})

-- Toggle
local myToggle = sControls:AddToggle({
	Label       = "Enable Feature",
	Description = "Turns this feature on or off",
	Default     = true,
	Callback    = function(value)
		libui:Notify({
			Title   = "Toggle Changed",
			Message = "Feature is now " .. (value and "enabled" or "disabled"),
			Type    = value and "success" or "info",
			Duration = 2.5,
		})
	end,
})

-- Slider
local mySlider = sControls:AddSlider({
	Label       = "Speed",
	Description = "Adjust the movement speed",
	Min         = 0,
	Max         = 100,
	Default     = 40,
	Step        = 5,
	Suffix      = "%",
	Callback    = function(value)
		-- value updated live
	end,
})

-- Button - Primary
sControls:AddButton({
	Label    = "Notify Success",
	Style    = "primary",
	Callback = function()
		libui:Notify({
			Title    = "Operation Complete",
			Message  = "Everything went according to plan.",
			Type     = "success",
			Duration = 3,
		})
	end,
})

-- Button - Danger
sControls:AddButton({
	Label    = "Notify Error",
	Style    = "danger",
	Callback = function()
		libui:Notify({
			Title    = "Error Occurred",
			Message  = "Something went wrong. Please try again.",
			Type     = "error",
			Duration = 4,
		})
	end,
})

-- Button - Ghost (secondary style)
sControls:AddButton({
	Label    = "Notify Warning",
	Style    = "ghost",
	Callback = function()
		libui:Notify({
			Title    = "Warning",
			Message  = "This action may have unintended consequences.",
			Type     = "warning",
			Duration = 3.5,
		})
	end,
})

-- ---- Section: Text Inputs ----
local sInputs = tabComponents:AddSection({
	Title = "Text Inputs",
})

-- TextBox with validation
local myTextBox = sInputs:AddTextBox({
	Label       = "Username",
	Description = "Enter your player name",
	Placeholder = "e.g. Player123",
	Default     = "",
	Validator   = function(text)
		if #text > 0 and #text < 3 then
			return false, "Username must be at least 3 characters"
		end
		return true
	end,
	Callback    = function(value)
		-- value changed
	end,
})

-- Dropdown
local myDropdown = sInputs:AddDropdown({
	Label       = "Select Team",
	Description = "Choose your preferred team",
	Items       = { "Builders", "Explorers", "Warriors", "Mages", "Rogues" },
	Default     = "Builders",
	Callback    = function(value)
		libui:Notify({
			Title    = "Team Selected",
			Message  = "You joined: " .. tostring(value),
			Type     = "info",
			Duration = 2,
		})
	end,
})

-- Multi-Dropdown
local myMultiDrop = sInputs:AddDropdown and sInputs.AddDropdown or nil
-- Use Section's direct component add (MultiDropdown)
do
	local MultiDropdown = require(script.Parent.Parent.components.MultiDropdown)
	local mdElement = MultiDropdown.new(sInputs._content, {
		Label       = "Abilities",
		Description = "Pick multiple abilities",
		Items       = { "Dash", "Shield", "Heal", "Stealth", "Fly", "Teleport" },
		Default     = { "Dash", "Shield" },
		Callback    = function(selected)
			-- selected is array of chosen values
		end,
	}, theme)
	table.insert(sInputs._elements, mdElement)
end

-- ---- Section: Color & Keybind ----
local sAdvanced = tabComponents:AddSection({
	Title = "Advanced Controls",
})

-- Color Picker
local myColorPicker = sAdvanced:AddColorPicker({
	Label    = "Accent Color",
	Default  = Color3.fromRGB(99, 102, 241),
	Callback = function(color)
		-- color updated
	end,
})

-- Keybind
local myKeybind = sAdvanced:AddKeybind({
	Label       = "Activate Keybind",
	Description = "Press to reassign the hotkey",
	Default     = Enum.KeyCode.RightShift,
	Callback    = function(keyCode)
		libui:Notify({
			Title    = "Keybind Set",
			Message  = "Bound to: " .. tostring(keyCode.Name),
			Type     = "info",
			Duration = 2.5,
		})
	end,
})

-- ============================================================
-- Tab 2: Theme
-- ============================================================
local tabTheme = win:AddTab({ Label = "Theme" })

local sThemeSection = tabTheme:AddSection({
	Title       = "Theme Switcher",
	Description = "Change the active color theme",
})

sThemeSection:AddButton({
	Label    = "Default (Dark)",
	Style    = "secondary",
	Callback = function()
		libui:SetTheme("Default")
		libui:Notify({
			Title    = "Theme Applied",
			Message  = "Switched to Default dark theme",
			Type     = "success",
			Duration = 2,
		})
	end,
})

sThemeSection:AddButton({
	Label    = "Midnight",
	Style    = "secondary",
	Callback = function()
		libui:SetTheme("Midnight")
		libui:Notify({
			Title    = "Theme Applied",
			Message  = "Switched to Midnight theme",
			Type     = "success",
			Duration = 2,
		})
	end,
})

sThemeSection:AddButton({
	Label    = "Light",
	Style    = "secondary",
	Callback = function()
		libui:SetTheme("Light")
		libui:Notify({
			Title    = "Theme Applied",
			Message  = "Switched to Light theme",
			Type     = "success",
			Duration = 2,
		})
	end,
})

-- Modal demo section
local sModalSection = tabTheme:AddSection({
	Title = "Modal & Context Menu",
})

sModalSection:AddButton({
	Label    = "Open Modal",
	Style    = "primary",
	Callback = function()
		local modal = libui:Modal({
			Title   = "Confirm Action",
			Message = "Are you sure you want to proceed? This action cannot be undone.",
			Width   = 380,
			Buttons = {
				{
					Label    = "Cancel",
					Style    = "secondary",
					Callback = function()
						libui:Notify({ Title = "Cancelled", Type = "info", Duration = 1.5 })
					end,
				},
				{
					Label    = "Confirm",
					Style    = "primary",
					Callback = function()
						libui:Notify({ Title = "Confirmed!", Message = "Action executed.", Type = "success", Duration = 2 })
					end,
				},
			},
		})
		modal:Show()
	end,
})

sModalSection:AddButton({
	Label    = "Show Context Menu",
	Style    = "secondary",
	Callback = function()
		local menu = libui:ContextMenu({
			Items = {
				{ Label = "Copy",        Callback = function() libui:Notify({ Title = "Copied", Type = "success", Duration = 1.5 }) end },
				{ Label = "Paste",       Callback = function() libui:Notify({ Title = "Pasted", Type = "success", Duration = 1.5 }) end },
				{ Separator = true },
				{ Label = "Rename",      Callback = function() libui:Notify({ Title = "Renaming...", Type = "info", Duration = 1.5 }) end },
				{ Label = "Delete", Danger = true, Callback = function() libui:Notify({ Title = "Deleted", Type = "error", Duration = 2 }) end },
			},
		})
		-- Show near center of screen
		local Players = game:GetService("Players")
		local sg = libui._screenGui
		if sg then
			local sz = sg.AbsoluteSize
			menu:Show(sz.X / 2 - 90, sz.Y / 2 - 80)
		end
	end,
})

-- ============================================================
-- Tab 3: About
-- ============================================================
local tabAbout = win:AddTab({ Label = "About" })

local sAboutSection = tabAbout:AddSection({
	Title       = "libui",
	Description = "A premium, polished UI framework for Roblox executor scripts",
})

sAboutSection:AddButton({
	Label    = "Version 1.0.0",
	Style    = "ghost",
	Callback = function()
		libui:Notify({
			Title    = "libui v1.0.0",
			Message  = "Dark mode glassmorphism, macOS-inspired design",
			Type     = "info",
			Duration = 3,
		})
	end,
})

sAboutSection:AddButton({
	Label    = "Run All Notifications",
	Style    = "primary",
	Callback = function()
		local types = {
			{ Title = "Information", Message = "Here is some useful info.", Type = "info" },
			{ Title = "Success",     Message = "The operation completed.",   Type = "success" },
			{ Title = "Warning",     Message = "Proceed with caution.",      Type = "warning" },
			{ Title = "Error",       Message = "Something went wrong.",      Type = "error" },
		}
		for i, n in ipairs(types) do
			task.delay(i * 0.6, function()
				libui:Notify({ Title = n.Title, Message = n.Message, Type = n.Type, Duration = 3.5 })
			end)
		end
	end,
})

local sCollapsible = tabAbout:AddSection({
	Title       = "Collapsible Section",
	Description = "Click to expand/collapse",
	Collapsible = true,
})

sCollapsible:AddToggle({
	Label   = "Hidden Toggle",
	Default = false,
})

sCollapsible:AddSlider({
	Label   = "Hidden Slider",
	Min     = 0,
	Max     = 50,
	Default = 25,
})

-- ============================================================
-- Tooltip example: attach to a demo button area
-- ============================================================
-- (Tooltips attach to existing GuiObjects)
-- Since we don't have direct access to the button GuiObject here,
-- we demonstrate tooltip in a post-init step.

task.delay(1.5, function()
	-- Find first button in the window to attach a tooltip to
	local contentArea = win._contentArea
	if contentArea then
		local firstBtn = contentArea:FindFirstChildWhichIsA("TextButton", true)
		if firstBtn then
			libui:Tooltip(firstBtn, "This is a tooltip — hover here for 0.5s")
		end
	end
end)

-- ============================================================
-- Print confirmation
-- ============================================================
print("[libui Demo] Loaded successfully — all components demonstrated")

return win
