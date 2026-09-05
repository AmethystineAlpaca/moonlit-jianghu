extends RefCounted

const INK := Color("0c181f")
const PAPER := Color("e9dfc6")
const GOLD := Color("b69a63")
const JADE := Color("8bb8ac")

static func font(serif: bool = false) -> Font:
	return load("res://assets/fonts/NotoSerifSC.ttf" if serif else "res://assets/fonts/NotoSansSC.ttf") as Font

static func panel(fill: Color = INK, border: Color = GOLD, padding: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color(border, 0.55)
	style.set_border_width_all(1)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 8
	return style

static func make() -> Theme:
	var result := Theme.new()
	result.default_font = font()
	result.default_font_size = 16
	result.set_color("font_color", "Label", PAPER)
	result.set_color("font_color", "Button", PAPER)
	result.set_color("font_hover_color", "Button", Color("fff1cf"))
	result.set_color("font_focus_color", "Button", Color("fff1cf"))
	result.set_stylebox("normal", "Button", panel(Color(0.04, 0.09, 0.12, 0.90), Color("57766c"), 14))
	result.set_stylebox("hover", "Button", panel(Color("233c3d"), GOLD, 14))
	result.set_stylebox("pressed", "Button", panel(Color("324c47"), PAPER, 14))
	result.set_stylebox("focus", "Button", panel(Color(0, 0, 0, 0), JADE, 14))
	result.set_stylebox("panel", "PanelContainer", panel())
	result.set_color("font_color", "CheckButton", PAPER)
	return result

static func label(text: String, size: int, color: Color = PAPER, serif: bool = false) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_override("font", font(serif))
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result
