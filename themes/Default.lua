-- libui/themes/Default.lua
-- Default dark theme for LibUI

local Default = {}

Default.Name = "Default"
Default.IsDark = true

-- ============================================================
-- Colors
-- ============================================================
Default.Colors = {
	-- Backgrounds
	BG        = Color3.fromRGB(11, 11, 15),
	Surface   = Color3.fromRGB(19, 19, 26),
	Surface2  = Color3.fromRGB(27, 27, 37),
	Surface3  = Color3.fromRGB(35, 35, 48),

	-- Borders (use with transparency)
	Border    = Color3.fromRGB(255, 255, 255),  -- apply at 0.07 transparency
	BorderSubtle = Color3.fromRGB(255, 255, 255), -- apply at 0.04 transparency

	-- Text
	Text      = Color3.fromRGB(238, 238, 245),
	TextSub   = Color3.fromRGB(130, 130, 148),
	TextMuted = Color3.fromRGB(75, 75, 90),

	-- Accent (indigo)
	Accent      = Color3.fromRGB(99, 102, 241),
	AccentHover = Color3.fromRGB(118, 121, 255),
	AccentPress = Color3.fromRGB(79, 82, 221),
	AccentSoft  = Color3.fromRGB(99, 102, 241),  -- apply at 0.15 transparency
	AccentText  = Color3.fromRGB(167, 169, 255),

	-- Semantic
	Success      = Color3.fromRGB(52, 199, 89),
	SuccessSoft  = Color3.fromRGB(52, 199, 89),  -- apply at 0.15 transparency
	Warning      = Color3.fromRGB(255, 159, 10),
	WarningSoft  = Color3.fromRGB(255, 159, 10), -- apply at 0.15 transparency
	Danger       = Color3.fromRGB(255, 59, 48),
	DangerHover  = Color3.fromRGB(255, 79, 68),
	DangerPress  = Color3.fromRGB(235, 39, 28),
	DangerSoft   = Color3.fromRGB(255, 59, 48),  -- apply at 0.15 transparency

	-- Misc
	White        = Color3.fromRGB(255, 255, 255),
	Black        = Color3.fromRGB(0, 0, 0),
	Transparent  = Color3.fromRGB(0, 0, 0),

	-- Overlay
	Overlay      = Color3.fromRGB(0, 0, 0),      -- apply at 0.5 transparency
	Scrim        = Color3.fromRGB(0, 0, 0),       -- apply at 0.7 transparency
}

-- ============================================================
-- Transparency values (used alongside Colors)
-- ============================================================
Default.Transparency = {
	Border        = 0.07,
	BorderSubtle  = 0.04,
	AccentSoft    = 0.15,
	SuccessSoft   = 0.15,
	WarningSoft   = 0.15,
	DangerSoft    = 0.15,
	WindowBG      = 0.15,
	Surface       = 0.08,
	Overlay       = 0.50,
	Scrim         = 0.70,
	ShadowStrong  = 0.50,
	ShadowSoft    = 0.75,
}

-- ============================================================
-- Fonts
-- ============================================================
Default.Fonts = {
	Heading  = Enum.Font.GothamBold,
	Body     = Enum.Font.Gotham,
	Caption  = Enum.Font.GothamLight,
	Mono     = Enum.Font.RobotoMono,
	SemiBold = Enum.Font.GothamSemibold,
}

-- ============================================================
-- Font Sizes
-- ============================================================
Default.FontSizes = {
	Xs   = 10,
	Sm   = 12,
	Base = 13,
	Md   = 14,
	Lg   = 16,
	Xl   = 18,
	Xxl  = 22,
	Huge = 28,
}

-- ============================================================
-- Spacing (base unit = 4px)
-- ============================================================
Default.Spacing = {
	Xs  = 4,
	Sm  = 8,
	Md  = 12,
	Lg  = 16,
	Xl  = 20,
	Xxl = 24,
	Xxxl = 32,
}

-- ============================================================
-- Border Radius
-- ============================================================
Default.Radius = {
	Window  = 12,
	Card    = 8,
	Button  = 6,
	Small   = 4,
	Pill    = 100,  -- fully rounded
	Full    = 999,
}

-- ============================================================
-- Shadows (ImageLabel approach with 9-slice)
-- ============================================================
Default.Shadows = {
	AssetId   = "rbxassetid://5554236805",
	SliceRect = Rect.new(23, 23, 277, 277),

	Window = {
		Color        = Color3.fromRGB(0, 0, 0),
		Transparency = 0.50,
		Size         = UDim2.new(1, 40, 1, 40),
		Position     = UDim2.new(0, -20, 0, -20),
	},
	Card = {
		Color        = Color3.fromRGB(0, 0, 0),
		Transparency = 0.65,
		Size         = UDim2.new(1, 24, 1, 24),
		Position     = UDim2.new(0, -12, 0, -12),
	},
	Popup = {
		Color        = Color3.fromRGB(0, 0, 0),
		Transparency = 0.45,
		Size         = UDim2.new(1, 32, 1, 32),
		Position     = UDim2.new(0, -16, 0, -16),
	},
}

-- ============================================================
-- Animations (references to Presets)
-- ============================================================
Default.Animations = {
	Hover = {
		Time      = 0.15,
		Style     = Enum.EasingStyle.Quart,
		Direction = Enum.EasingDirection.Out,
	},
	Normal = {
		Time      = 0.25,
		Style     = Enum.EasingStyle.Quart,
		Direction = Enum.EasingDirection.Out,
	},
	Slow = {
		Time      = 0.40,
		Style     = Enum.EasingStyle.Quart,
		Direction = Enum.EasingDirection.InOut,
	},
	Intro = {
		Time      = 0.35,
		Style     = Enum.EasingStyle.Quint,
		Direction = Enum.EasingDirection.Out,
	},
	Bounce = {
		Time      = 0.50,
		Style     = Enum.EasingStyle.Back,
		Direction = Enum.EasingDirection.Out,
	},
}

-- ============================================================
-- Component-specific tokens
-- ============================================================
Default.Components = {
	Window = {
		TitleBarHeight  = 44,
		TabBarHeight    = 36,
		MinWidth        = 320,
		MinHeight       = 240,
		DefaultWidth    = 560,
		DefaultHeight   = 420,
	},
	Button = {
		Height    = 34,
		PaddingH  = 14,
		IconSize  = 16,
	},
	Toggle = {
		Width   = 42,
		Height  = 24,
		Thumb   = 18,
		Padding = 3,
	},
	Slider = {
		Height      = 4,
		ThumbSize   = 16,
		RowHeight   = 48,
	},
	Input = {
		Height    = 36,
		PaddingH  = 12,
	},
	Dropdown = {
		Height     = 36,
		ItemHeight = 32,
		MaxVisible = 5,
	},
	Notification = {
		Width       = 300,
		MinHeight   = 60,
		MaxVisible  = 5,
		Gap         = 8,
	},
	Tooltip = {
		Delay    = 0.5,
		Padding  = 8,
		MaxWidth = 220,
	},
	Tab = {
		IndicatorHeight = 2,
		PaddingH        = 16,
	},
}

return Default
