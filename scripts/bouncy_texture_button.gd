class_name BouncyTextureButton extends TextureButton

@export var hover_scale: float = 1.1
@export var pressed_scale_addition: float = 0.05
@export var animation_duration: float = 0.2

var scale_tween: Tween

func _ready() -> void :
	mouse_entered.connect( func():
		pivot_offset = size / 2

		if disabled:
			return

		if scale_tween and scale_tween.is_running():
			scale_tween.stop()

		scale_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		scale_tween.tween_property(self, "scale", Vector2.ONE * hover_scale, animation_duration)
	)

	mouse_exited.connect( func():
		pivot_offset = size / 2

		if scale_tween and scale_tween.is_running():
			scale_tween.stop()

		scale_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		scale_tween.tween_property(self, "scale", Vector2.ONE, animation_duration)
	)

func _pressed() -> void :
	pivot_offset = size / 2

	#AudioManager.play(AudioManager.SoundEffects.DOUBLE_CLICK, randf_range(0.8, 1.2))

	if scale_tween and scale_tween.is_running():
		scale_tween.stop()

	scale_tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", Vector2.ONE * hover_scale, 0.3).from(Vector2.ONE * (hover_scale - pressed_scale_addition))
