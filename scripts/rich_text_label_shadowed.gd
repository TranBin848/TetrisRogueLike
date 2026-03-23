@tool
class_name RichTextLabelShadowed extends RichTextLabel

@export var font_family: LabelShadowed.FontFamily = LabelShadowed.FontFamily.SMALL:
	set(value):
		font_family = value
		_update_font()

@export var shadow_enabled: bool = true:
	set(value):
		shadow_enabled = value
		_update_shadow()

@export var shadow_color: Color = Color("1b1b1b"):
	set(value):
		shadow_color = value
		_update_shadow()

@export var shadow_offset: int = 2:
	set(value):
		shadow_offset = value
		_update_shadow()

@export var outline_enabled: bool = true:
	set(value):
		outline_enabled = value
		_update_outline()

@export var outline_size: int = 4:
	set(value):
		outline_size = value
		_update_outline()

@export var outline_color: Color = Color.BLACK:
	set(value):
		outline_color = value
		_update_outline()

func _get_font_variation() -> FontVariation:
	var is_alternative_font: bool = LabelShadowed.should_use_alternative_font_for_family(font_family)

	if is_alternative_font:

		var locale: String = TranslationServer.get_locale()
		var is_cjk: bool = locale.begins_with("zh") or locale.begins_with("ja") or locale.begins_with("ko")

		if is_cjk:
			return LabelShadowed.LARGE_FONT_CJK_VARIATION
		else:
			return LabelShadowed.SMALL_FONT_CJK_VARIATION if font_family == LabelShadowed.FontFamily.SMALL else LabelShadowed.LARGE_FONT_CJK_VARIATION
	else:
		return LabelShadowed.SMALL_FONT_VARIATION if font_family == LabelShadowed.FontFamily.SMALL else LabelShadowed.LARGE_FONT_VARIATION

func _get_font_size() -> int:
	var is_alternative_font: bool = LabelShadowed.should_use_alternative_font_for_family(font_family)

	if is_alternative_font:

		var locale: String = TranslationServer.get_locale()
		var is_cjk: bool = locale.begins_with("zh") or locale.begins_with("ja") or locale.begins_with("ko")

		if is_cjk:
			return 11
		else:
			return 8 if font_family == LabelShadowed.FontFamily.SMALL else 11
	else:
		return 16

func _update_font() -> void :
	add_theme_font_override("normal_font", _get_font_variation())
	add_theme_font_size_override("normal_font_size", _get_font_size())

func _ready() -> void :
	_update_font()
	_update_shadow()
	_update_outline()

func _notification(what: int) -> void :
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_font()

func _update_shadow() -> void :
	if shadow_enabled:
		add_theme_constant_override("shadow_offset_x", shadow_offset)
		add_theme_constant_override("shadow_offset_y", shadow_offset)
		add_theme_color_override("font_shadow_color", shadow_color)

		if outline_enabled:
			add_theme_constant_override("shadow_outline_size", outline_size)
	else:
		remove_theme_constant_override("shadow_offset_x")
		remove_theme_constant_override("shadow_offset_y")
		remove_theme_color_override("font_shadow_color")
		remove_theme_constant_override("shadow_outline_size")

func _update_outline() -> void :
	if outline_enabled:
		add_theme_constant_override("outline_size", outline_size)
		add_theme_color_override("font_outline_color", outline_color)

		if shadow_enabled:
			add_theme_constant_override("shadow_outline_size", outline_size)
	else:
		remove_theme_constant_override("outline_size")
		remove_theme_color_override("font_outline_color")
		remove_theme_constant_override("shadow_outline_size")
