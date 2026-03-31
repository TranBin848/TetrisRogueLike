class_name PointNotification extends Control

const RED_BACKGROUND_STYLE: StyleBoxTexture = preload("res://resources/point_notification_red.tres")
const BLUE_BACKGROUND_STYLE: StyleBoxTexture = preload("res://resources/point_notification_blue.tres")
const GRAY_BACKGROUND_STYLE: StyleBoxTexture = preload("res://resources/point_notification_gray.tres")

const BACKGROUND_ANIMATION_DURATION: float = 0.2
const LABEL_ANIMATION_DURATION: float = 0.5
const FADE_OUT_DURATION: float = 0.1

const UP: float = - PI / 2
const DOWN: float = PI / 2

enum {
	BLUE, 
	RED, 
	GRAY
}


@onready var label: Label = $Label
@onready var background: PanelContainer = $Background


static func create(pos: Vector2, type: int, value: Variant, pitch: float) -> PointNotification:
	var scene: PackedScene = preload("res://scenes/point_notification.tscn")
	var instance: PointNotification = scene.instantiate()

	GameManager.get_current_scene().get_node("%PointNotificationContainer").add_child(instance)

	instance.global_position = pos
	instance.animate(type, value, pitch)
	return instance


static func create_and_slide(pos: Vector2, type: int, value: Variant, pitch: float = 1.8, direction: float = PointNotification.UP, distance: float = 6.0) -> PointNotification:
	var p: PointNotification = create(pos, type, value, pitch)
	p.slide_animation(direction, distance)
	return p


func animate(type: int, value: Variant, pitch: float) -> void :
	if type == BLUE:
		label.add_theme_color_override("font_shadow_color", Color("0069aa"))
		label.add_theme_color_override("font_outline_color", Color("0069aa"))
		background.add_theme_stylebox_override("panel", BLUE_BACKGROUND_STYLE)

	elif type == RED:
		label.add_theme_color_override("font_shadow_color", Color("891e2b"))
		label.add_theme_color_override("font_outline_color", Color("891e2b"))
		background.add_theme_stylebox_override("panel", RED_BACKGROUND_STYLE)

	elif type == GRAY:
		label.add_theme_color_override("font_shadow_color", Color("3d3d3d"))
		label.add_theme_color_override("font_outline_color", Color("3d3d3d"))
		background.add_theme_stylebox_override("panel", GRAY_BACKGROUND_STYLE)


	if value is String:
		label.text = value
	elif value is int:
		label.text = Utils.add_commas_to_number(value)
		if value > 0:
			label.text = "+" + Utils.add_commas_to_number(value)
	else:

		label.text = Utils.add_commas_to_number(value)

	#AudioManager.play(AudioManager.SoundEffects.POP, pitch)

	label.pivot_offset = label.size / 2

	var background_tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	background_tween.parallel().tween_property(background, "scale", Vector2.ONE, 0.3 / GameManager.timescale).from(Vector2(1.6, 0.0))
	background_tween.set_ease(Tween.EASE_IN)
	background_tween.tween_property(background, "scale:y", 0.0, 0.3 / GameManager.timescale).set_delay(0.3 / GameManager.timescale)

	var label_tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	label_tween.tween_property(label, "scale", Vector2.ONE, 0.3 / GameManager.timescale).from(Vector2.ONE * 0.75)
	label_tween.set_trans(Tween.TRANS_QUAD)
	label_tween.tween_property(label, "scale:y", 0.0, 0.2 / GameManager.timescale).set_delay(0.5 / GameManager.timescale)

	background_tween.tween_callback( func():
		queue_free()
	)


func slide_animation(direction: float, distance: float = 8.0) -> void :
	global_position += Vector2(8, 0).rotated(direction)

	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", global_position + Vector2(distance, 0).rotated(direction), 0.5 / GameManager.timescale)
