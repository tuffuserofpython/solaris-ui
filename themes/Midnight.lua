-- libui/themes/Midnight.lua
-- Deep dark/midnight variant theme for LibUI

local Midnight = {}

Midnight.Name = "Midnight"
Midnight.IsDark = true

-- ============================================================
-- Colors
-- ============================================================
Midnight.Colors = {
	-- Backgrounds (pure blacks)
	BG        = Color3.fromRGB(0, 0, 0),
	Surface   = Color3.fromRGB(8, 8, 12),
	Surface2  = Color3.fromRGB(14, 14, 20),
	Surface3  = Color3.fromRGB(20, 20, 30),

	-- Borders
	Border       = Color3.fromRGB(255, 255, 255), -- apply at 0.06 transparency
	BorderSubtle = Color3.fromRGB(255, 255, 255), -- apply at 0.03 transparency

	-- Text (high contrast)
	Text      = Color3.fromRGB(248, 248, 255),
	TextSub   = Color3.fromRGB(150, 150, 170),
	TextMuted = Color3.fromRGB(70, 70, 85),

	-- Accent (violet/purple for midnight feel)
	Accent      = Color3.fromRGB(139, 92, 246),
	AccentHover = Color3.fromRGB(159, 112, 255),
	AccentPress = Color3.fromRGB(119, 72, 226),
	AccentSoft  = Color3.fromRGB(139, 92, 246),  -- apply at 0.18 transparency
	AccentText  = Color3.fromRGB(196, 167, 255),

	-- Semantic
	Success      = Color3.fromRGB(52, 211, 92),
	SuccessSoft  = Color3.fromRGB(52, 211, 92),
	Warning      = Color3.fromRGB(251, 191, 36),
	WarningSoft  = Color3.fromRGB(251, 191, 36),
	Danger       = Color3.fromRGB(248, 113, 113),
	DangerHover  = Color3.fromRGB(255, 133, 133),
	DangerPress  = Color3.fromRGB(228, 93, 93),
	DangerSoft   = Color3.fromRGB(248, 113, 113),

	-- Misc
	White        = Color3.fromRGB(255, 255, 255),
	Black        = Color3.fromRGB(0, 0, 0),
	Transparent  = Color3.fromRGB(0, 0, 0),

	-- Overlay
	Overlay      = Color3.fromRGB(0, 0, 0),
	Scrim        = Color3.fromRGB(0, 0, 0),
}

-- ============================================================
-- Transparency values
-- ============================================================
Midnight.Transparency = {
	Border        = 0.06,
	BorderSubtle  = 0.03,
	AccentSoft    = 0.18,
	SuccessSoft   = 0.18,
	WarningSoft   = 0.18,
	DangerSoft    = 0.18,
	WindowBG      = 0.10,
	Surface       = 0.05,
	Overlay       = 0.60,
	Scrim         = 0.80,
	ShadowStrong  = 0.30,
	ShadowSoft    = 0.55,
}

-- ============================================================
-- Fonts (same as default)
-- ============================================================
Midnight.Fonts = {
	Heading  = Enum.Font.GothamBold,
	Body     = Enum.Font.Gotham,
	Caption  = Enum.Font.GothamLight,
	Mono     = Enum.Font.RobotoMono,
	SemiBold = Enum.Font.GothamSemibold,
}

-- ============================================================
-- Font Sizes (same as default)
-- ============================================================
Midnight.FontSizes = {
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
-- Spacing
-- ============================================================
Midnight.Spacing = {
	Xs   = 4,
	Sm   = 8,
	Md   = 12,
	Lg   = 16,
	Xl   = 20,
	Xxl  = 24,
	Xxxl = 32,
}

-- ============================================================
-- Border Radius
-- ============================================================
Midnight.Radius = {
	Window = 14,  -- slightly larger for midnight feel
	Card   = 10,
	Button = 7,
	Small  = 4,
	Pill   = 100,
	Full   = 999,
}

-- ============================================================
-- Shadows (deeper for midnight)
-- ============================================================
Midnight.Shadows = {
	AssetId   = "rbxassetid://5554236805",
	SliceRect = Rect.new(23, 23, 277, 277),

	Window = {
		Color        = Color3.fromRGB(0, 0, 0),
		Transparency = 0.25,
		Size         = UDim2.new(1, 60, 1, 60),
		Position     = UDim2.new(0, -30, 0, -30),
	},
	Card = {
		Color        = Color3.fromRGB(0, 0, 0),
		Transparency = 0.45,
		Size         = UDim2.new(1, 30, 1, 30),
		Position     = UDim2.new(0, -15, 0, -15),
	},
	Popup = {
		Color        = Color3.fromRGB(0, 0, 0),
		Transparency = 0.30,
		Size         = UDim2.new(1, 40, 1, 40),
		Position     = UDim2.new(0, -20, 0, -20),
	},
}

-- ============================================================
-- Animations (slightly slower for dramatic midnight feel)
-- ============================================================
Midnight.Animations = {
	Hover = {
		Time      = 0.18,
		Style     = Enum.EasingStyle.Quart,
		Direction = Enum.EasingDirection.Out,
	},
	Normal = {
		Time      = 0.28,
		Style     = Enum.EasingStyle.Quart,
		Direction = Enum.EasingDirection.Out,
	},
	Slow = {
		Time      = 0.45,
		Style     = Enum.EasingStyle.Quart,
		Direction = Enum.EasingDirection.InOut,
	},
	Intro = {
		Time      = 0.40,
		Style     = Enum.EasingStyle.Quint,
		Direction = Enum.EasingDirection.Out,
	},
	Bounce = {
		Time      = 0.55,
		Style     = Enum.EasingStyle.Back,
		Direction = Enum.EasingDirection.Out,
	},
}

-- ============================================================
-- Component-specific tokens
-- ============================================================
Midnight.Components = {
	Window = {
		TitleBarHeight  = 46,
		TabBarHeight    = 38,
		MinWidth        = 320,
		MinHeight       = 240,
		DefaultWidth    = 580,
		DefaultHeight   = 440,
	},
	Button = {
		Height    = 36,
		PaddingH  = 16,
		IconSize  = 16,
	},
	Toggle = {
		Width   = 44,
		Height  = 26,
		Thumb   = 20,
		Padding = 3,
	},
	Slider = {
		Height      = 4,
		ThumbSize   = 18,
		RowHeight   = 50,
	},
	Input = {
		Height    = 38,
		PaddingH  = 14,
	},
	Dropdown = {
		Height     = 38,
		ItemHeight = 34,
		MaxVisible = 5,
	},
	Notification = {
		Width       = 310,
		MinHeight   = 64,
		MaxVisible  = 5,
		Gap         = 10,
	},
	Tooltip = {
		Delay    = 0.5,
		Padding  = 8,
		MaxWidth = 220,
	},
	Tab = {
		IndicatorHeight = 2,
		PaddingH        = 18,
	},
}

return Midnight
