-- libui/examples/Basic.lua
-- Minimal, well-commented example showing basic libui usage.
-- Intended as a quick-start reference.

-- ============================================================
-- Step 1: Require libui
-- In a standard Studio LocalScript:
--   local libui = require(game.ServerStorage.libui)  -- or wherever you placed it
-- In an executor, you may use loadstring or a require path.
-- ============================================================

local libui = require(script.Parent.Parent)  -- adjust path as needed

-- ============================================================
-- Step 2: Initialize the library (optional — auto-inits on first use)
-- You can pass a Theme name: "Default", "Light", or "Midnight"
-- ============================================================

libui:Init({
	Theme = "Default",  -- dark glassmorphism theme
})

-- ============================================================
-- Step 3: Create a window
-- ============================================================

local window = libui:Window({
	Title    = "Basic Example",
	Subtitle = "libui quick-start",
	Size     = { X = 480, Y = 380 },
})

-- ============================================================
-- Step 4: Add a tab
-- ============================================================

local mainTab = window:AddTab({
	Label = "Main",
})

-- ============================================================
-- Step 5: Add a section inside the tab
-- ============================================================

local section = mainTab:AddSection({
	Title       = "Settings",
	Description = "Configure your preferences",
})

-- ============================================================
-- Step 6: Add components to the section
-- ============================================================

-- Toggle
local toggle = section:AddToggle({
	Label    = "Auto-Run",
	Default  = false,
	Callback = function(value)
		-- Called every time the toggle changes
		print("Auto-Run:", value)
	end,
})

-- Slider
local slider = section:AddSlider({
	Label    = "Walk Speed",
	Min      = 8,
	Max      = 100,
	Default  = 16,
	Step     = 2,
	Suffix   = " st/s",
	Callback = function(value)
		-- Called while dragging and on release
		local character = game.Players.LocalPlayer.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = value
			end
		end
	end,
})

-- TextBox
local textbox = section:AddTextBox({
	Label       = "Script Name",
	Placeholder = "Enter script name...",
	Default     = "",
	Callback    = function(value)
		-- Called when focus is lost
		print("Script name:", value)
	end,
})

-- Dropdown
local dropdown = section:AddDropdown({
	Label    = "Teleport Location",
	Items    = { "Spawn", "Arena", "Shop", "VIP Lounge" },
	Default  = "Spawn",
	Callback = function(value)
		print("Selected location:", value)
	end,
})

-- Button
section:AddButton({
	Label    = "Apply Settings",
	Style    = "primary",
	Callback = function()
		-- Read current values from components
		local isAutoRun  = toggle:Get()
		local walkSpeed  = slider:Get()
		local scriptName = textbox:Get()
		local location   = dropdown:Get()

		print(("Applying: AutoRun=%s, Speed=%d, Name=%s, Location=%s"):format(
			tostring(isAutoRun), walkSpeed, scriptName, tostring(location)
		))

		-- Show a notification to confirm
		libui:Notify({
			Title    = "Settings Applied",
			Message  = "Your changes have been saved.",
			Type     = "success",
			Duration = 3,
		})
	end,
})

-- ============================================================
-- Step 7 (optional): A second, collapsible section
-- ============================================================

local advancedSection = mainTab:AddSection({
	Title       = "Advanced",
	Collapsible = true,  -- User can click header to expand/collapse
})

advancedSection:AddColorPicker({
	Label    = "UI Color",
	Default  = Color3.fromRGB(99, 102, 241),
	Callback = function(color)
		print("Color picked:", color)
	end,
})

advancedSection:AddKeybind({
	Label    = "Toggle UI",
	Default  = Enum.KeyCode.RightShift,
	Callback = function(key)
		print("New keybind:", key.Name)
	end,
})

-- ============================================================
-- Step 8 (optional): Show a modal dialog
-- ============================================================

-- Example: show a confirm dialog when the window is first opened
task.delay(0.5, function()
	local modal = libui:Modal({
		Title   = "Welcome",
		Message = "Welcome to libui! This is a basic usage example.\n\nExplore the components in the window above.",
		Buttons = {
			{ Label = "Get Started", Style = "primary" },
		},
	})
	modal:Show()
end)

-- ============================================================
-- Done! The window is now visible with all components ready.
-- ============================================================

print("[libui Basic] Example loaded successfully")
