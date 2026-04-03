class_name PixelToggleButton extends TextureButton


const HOVER_COLOR: Color = Color(1.2, 1.2, 1.2)


var scale_tween: Tween


func _ready() -> void :
	mouse_entered.connect( func():
		if disabled:
			return

		modulate = HOVER_COLOR
	)

	mouse_exited.connect( func():
		modulate = Color.WHITE
	)


func _pressed() -> void :
	#AudioManager.play(AudioManager.SoundEffects.DOUBLE_CLICK, randf_range(0.8, 1.2))

	pivot_offset = size / 2

	if scale_tween and scale_tween.is_running():
		scale_tween.stop()
		scale_tween = null

	scale_tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", Vector2.ONE, 0.3).from(Vector2.ONE * 1.35)
