-- libui/themes/Light.lua
-- Light variant theme for LibUI

local Light = {}

Light.Name = "Light"
Light.IsDark = false

-- ============================================================
-- Colors
-- ============================================================
Light.Colors = {
	-- Backgrounds (light)
	BG        = Color3.fromRGB(242, 242, 247),
	Surface   = Color3.fromRGB(255, 255, 255),
	Surface2  = Color3.fromRGB(246, 246, 250),
	Surface3  = Color3.fromRGB(237, 237, 243),

	-- Borders
	Border       = Color3.fromRGB(0, 0, 0),      -- apply at 0.10 transparency
	BorderSubtle = Color3.fromRGB(0, 0, 0),       -- apply at 0.06 transparency

	-- Text
	Text      = Color3.fromRGB(16, 16, 20),
	TextSub   = Color3.fromRGB(80, 80, 98),
	TextMuted = Color3.fromRGB(155, 155, 168),

	-- Accent (indigo)
	Accent      = Color3.fromRGB(79, 82, 221),
	AccentHover = Color3.fromRGB(65, 68, 207),
	AccentPress = Color3.fromRGB(55, 58, 197),
	AccentSoft  = Color3.fromRGB(99, 102, 241),  -- apply at 0.12 transparency
	AccentText  = Color3.fromRGB(59, 62, 201),

	-- Semantic
	Success      = Color3.fromRGB(34, 177, 71),
	SuccessSoft  = Color3.fromRGB(52, 199, 89),
	Warning      = Color3.fromRGB(230, 139, 0),
	WarningSoft  = Color3.fromRGB(255, 159, 10),
	Danger       = Color3.fromRGB(230, 39, 28),
	DangerHover  = Color3.fromRGB(210, 19, 8),
	DangerPress  = Color3.fromRGB(190, 0, 0),
	DangerSoft   = Color3.fromRGB(255, 59, 48),

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
Light.Transparency = {
	Border        = 0.10,
	BorderSubtle  = 0.06,
	AccentSoft    = 0.12,
	SuccessSoft   = 0.12,
	WarningSoft   = 0.12,
	DangerSoft    = 0.12,
	WindowBG      = 0.05,
	Surface       = 0.03,
	Overlay       = 0.40,
	Scrim         = 0.60,
	ShadowStrong  = 0.75,
	ShadowSoft    = 0.88,
}

-- ============================================================
-- Fonts (same as default)
-- ============================================================
Light.Fonts = {
	Heading  = Enum.Font.GothamBold,
	Body     = Enum.Font.Gotham,
	Caption  = Enum.Font.GothamLight,
	Mono     = Enum.Font.RobotoMono,
	SemiBold = Enum.Font.GothamSemibold,
}

-- ============================================================
-- Font Sizes (same as default)
-- ============================================================
Light.FontSizes = {
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
Light.Spacing = {
	Xs   = 4,
	Sm   = 8,
	Md   = 12,
	Lg   = 16,
	Xl   = 20,
	Xxl  = 24,
	Xxxl = 32,
}

-- ============================================================
-- Border Radius (same as default)
-- ============================================================
Light.Radius = {
	Window = 12,
	Card   = 8,
	Button = 6,
	Small  = 4,
	Pill   = 100,
	Full   = 999,
}

-- ============================================================
-- Shadows
-- ============================================================
Light.Shadows = {
	AssetId   = "rbxassetid://5554236805",
	SliceRect = Rect.new(23, 23, 277, 277),

	Window = {
		Color        = Color3.fromRGB(0, 0, 0),
		Transparency = 0.75,
		Size         = UDim2.new(1, 40, 1, 40),
		Position     = UDim2.new(0, -20, 0, -20),
	},
	Card = {
		Color        = Color3.fromRGB(0, 0, 0),
		Transparency = 0.85,
		Size         = UDim2.new(1, 24, 1, 24),
		Position     = UDim2.new(0, -12, 0, -12),
	},
	Popup = {
		Color        = Color3.fromRGB(0, 0, 0),
		Transparency = 0.72,
		Size         = UDim2.new(1, 32, 1, 32),
		Position     = UDim2.new(0, -16, 0, -16),
	},
}

-- ============================================================
-- Animations (same timings as default)
-- ============================================================
Light.Animations = {
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
-- Component-specific tokens (same structure as default)
-- ============================================================
Light.Components = {
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

return Light
