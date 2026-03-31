class_name BouncyButton extends Button

@export var hover_scale: float = 1.1
@export var pressed_scale_addition: float = 0.05
@export var animation_duration: float = 0.2

var scale_tween: Tween

func _get_font_variation() -> FontVariation:
	var is_alternative_font: bool = LabelShadowed.should_use_alternative_font_for_family(LabelShadowed.FontFamily.LARGE)

	if is_alternative_font:
		return LabelShadowed.LARGE_FONT_CJK_VARIATION
	else:
		return LabelShadowed.LARGE_FONT_VARIATION

func _get_font_size() -> int:
	var is_alternative_font: bool = LabelShadowed.should_use_alternative_font_for_family(LabelShadowed.FontFamily.LARGE)

	if is_alternative_font:
		return 11
	else:
		return 16

func _update_font() -> void :
	add_theme_font_override("font", _get_font_variation())
	add_theme_font_size_override("font_size", _get_font_size())

func _ready() -> void :
	_update_font()

	mouse_entered.connect( func():
		pivot_offset = size / 2

		if disabled:
			return

		if scale_tween and scale_tween.is_running():
			scale_tween.stop()

		scale_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		scale_tween.tween_property(self, "scale", Vector2.ONE * hover_scale, animation_duration)
	)

	mouse_exited.connect(_mouse_exited_animation)


func _notification(what: int) -> void :
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_font()


func _pressed() -> void :
	pivot_offset = size / 2


	if scale_tween and scale_tween.is_running():
		scale_tween.stop()

	scale_tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", scale, 0.3).from(scale * 0.9)


func _mouse_exited_animation() -> void :
	pivot_offset = size / 2

	if scale_tween and scale_tween.is_running():
		scale_tween.stop()

	scale_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", Vector2.ONE, animation_duration)
