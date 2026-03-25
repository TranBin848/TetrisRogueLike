@tool
class_name LabelShadowed extends MarginContainer

enum FontFamily{
	SMALL, 
	LARGE, 
}

const SHADOW_OFFSET: int = 2

const SMALL_FONT_VARIATION: FontVariation = preload("res://fonts/tiny_unicode_trimmed.tres")
const LARGE_FONT_VARIATION: FontVariation = preload("res://fonts/awesome_9_trimmed.tres")
const SMALL_FONT_CJK_VARIATION: FontVariation = preload("res://fonts/quan_trimmed.tres")
const LARGE_FONT_CJK_VARIATION: FontVariation = preload("res://fonts/lana_pixel_trimmed.tres")

static func should_use_alternative_font() -> bool:
	var locale: String = TranslationServer.get_locale()
	return locale.begins_with("zh") or locale.begins_with("ja") or locale.begins_with("ko") or locale.begins_with("pl") or locale.begins_with("ru") or locale.begins_with("tr")

static func should_use_alternative_font_for_family(family: FontFamily) -> bool:
	var locale: String = TranslationServer.get_locale()


	if family == FontFamily.SMALL:
		return locale.begins_with("zh") or locale.begins_with("ja") or locale.begins_with("ko") or locale.begins_with("pl") or locale.begins_with("ru") or locale.begins_with("tr")


	return locale.begins_with("zh") or locale.begins_with("ja") or locale.begins_with("ko")

@export var font_family: FontFamily = FontFamily.SMALL:
	set(value):
		font_family = value

		if is_instance_valid(label):
			label.add_theme_font_override("font", _get_font_variation())
			label.add_theme_font_size_override("font_size", _get_font_size())

@export_multiline var text: String:
	set(value):
		text = value

		if is_instance_valid(label):
			label.text = tr(text)

@export var font_color: Color = Color.WHITE:
	set(value):
		font_color = value

		if is_instance_valid(label):
			label.add_theme_color_override("font_color", font_color)

@export var shadow_enabled: bool = true:
	set(value):
		shadow_enabled = value
		_update_shadow()

@export var shadow_color: Color = Color("1b1b1b"):
	set(value):
		shadow_color = value
		_update_shadow()

@export var shadow_offset: int = SHADOW_OFFSET:
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

@export var autowrap_mode: TextServer.AutowrapMode = TextServer.AutowrapMode.AUTOWRAP_OFF:
	set(value):
		autowrap_mode = value

		if is_instance_valid(label):
			label.autowrap_mode = autowrap_mode


@export_subgroup("Alignment")

@export var horizontal_alignment: = HORIZONTAL_ALIGNMENT_LEFT:
	set(value):
		horizontal_alignment = value

		if is_instance_valid(label):
			label.horizontal_alignment = horizontal_alignment

@export var vertical_alignment: = VERTICAL_ALIGNMENT_TOP:
	set(value):
		vertical_alignment = value

		if is_instance_valid(label):
			label.vertical_alignment = vertical_alignment

@onready var label: Label = get_node_or_null("Label")

func _get_font_variation() -> FontVariation:
	var is_alternative_font: bool = should_use_alternative_font_for_family(font_family)

	if is_alternative_font:

		var locale: String = TranslationServer.get_locale()
		var is_cjk: bool = locale.begins_with("zh") or locale.begins_with("ja") or locale.begins_with("ko")

		if is_cjk:
			return LARGE_FONT_CJK_VARIATION
		else:
			return SMALL_FONT_CJK_VARIATION if font_family == FontFamily.SMALL else LARGE_FONT_CJK_VARIATION
	else:
		return SMALL_FONT_VARIATION if font_family == FontFamily.SMALL else LARGE_FONT_VARIATION

func _get_font_size() -> int:
	var is_alternative_font: bool = should_use_alternative_font_for_family(font_family)

	if is_alternative_font:

		var locale: String = TranslationServer.get_locale()
		var is_cjk: bool = locale.begins_with("zh") or locale.begins_with("ja") or locale.begins_with("ko")

		if is_cjk:
			return 11
		else:
			return 8 if font_family == FontFamily.SMALL else 11
	else:
		return 16


static func create(parent: Node) -> LabelShadowed:
	var scene: PackedScene = preload("res://scenes/ui/shadowed_label.tscn")
	var instance: LabelShadowed = scene.instantiate()

	parent.add_child(instance)

	return instance


func _ready() -> void :
	label.text = tr(text)
	label.add_theme_font_override("font", _get_font_variation())

	label.horizontal_alignment = horizontal_alignment
	label.vertical_alignment = vertical_alignment
	label.autowrap_mode = autowrap_mode

	label.add_theme_color_override("font_color", font_color)
	label.add_theme_font_size_override("font_size", _get_font_size())

	_update_shadow()
	_update_outline()

func _notification(what: int) -> void :
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if is_instance_valid(label):
			label.add_theme_font_override("font", _get_font_variation())
			label.add_theme_font_size_override("font_size", _get_font_size())
			label.text = tr(text)

func _update_shadow() -> void :
	if not is_instance_valid(label):
		return

	if shadow_enabled:
		label.add_theme_constant_override("shadow_offset_x", shadow_offset)
		label.add_theme_constant_override("shadow_offset_y", shadow_offset)
		label.add_theme_color_override("font_shadow_color", shadow_color)

		if outline_enabled:
			label.add_theme_constant_override("shadow_outline_size", outline_size)

		add_theme_constant_override("margin_bottom", shadow_offset)
		add_theme_constant_override("margin_right", shadow_offset)
	else:
		label.remove_theme_constant_override("shadow_offset_x")
		label.remove_theme_constant_override("shadow_offset_y")
		label.remove_theme_color_override("font_shadow_color")
		label.remove_theme_constant_override("shadow_outline_size")

		add_theme_constant_override("margin_bottom", 0)
		add_theme_constant_override("margin_right", 0)

func _update_outline() -> void :
	if not is_instance_valid(label):
		return

	if outline_enabled:
		label.add_theme_constant_override("outline_size", outline_size)
		label.add_theme_color_override("font_outline_color", outline_color)

		if shadow_enabled:
			label.add_theme_constant_override("shadow_outline_size", outline_size)
	else:
		label.remove_theme_constant_override("outline_size")
		label.remove_theme_color_override("font_outline_color")
		label.remove_theme_constant_override("shadow_outline_size")
