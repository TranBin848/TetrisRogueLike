class_name Tooltip extends PanelContainer

enum AnchorMode{
	HORIZONTAL, 
	VERTICAL
}

const MARGIN_DEFAULT: float = 12
const VIEW_WIDTH: int = 480
const VIEW_HEIGHT: int = 270


static var _instance: Tooltip = null
static var _last_requested_by: Node = null

var _tween: Tween = null
var _target_position: Vector2 = Vector2.ZERO
var _animation_y_addition: float = 0.0
var _anchor_mode: AnchorMode = AnchorMode.HORIZONTAL
var _margin: float = MARGIN_DEFAULT


@onready var title_label: LabelShadowed = $VBoxContainer / TitleLabel
@onready var description_label: RichTextLabelShadowed = $VBoxContainer / DescriptionLabel


static func appear_animation(from: Node, target_position: Vector2, title: String, description: String, anchor_point: AnchorMode = AnchorMode.HORIZONTAL, margin: float = MARGIN_DEFAULT, title_color: Color = Color.WHITE) -> void :
	if not is_instance_valid(_instance):
		return

	if _instance.visible and _instance._last_requested_by == from:
		return

	_instance.visible = true
	_instance._target_position = target_position
	_instance._anchor_mode = anchor_point

	Tooltip._last_requested_by = from

	_instance.title_label.text = title
	_instance.title_label.font_color = title_color
	_instance.description_label.text = GameManager.replace_tags(description)

	_instance._margin = margin

	if _instance._tween and _instance._tween.is_running():
		_instance._tween.stop()

	_instance._tween = _instance.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).set_parallel()
	_instance._tween.tween_property(_instance, "modulate:a", 1, 0.1).from(0)
	_instance._tween.set_trans(Tween.TRANS_BACK)
	_instance._tween.tween_property(_instance, "_animation_y_addition", 0, 0.3).from(4)

	#AudioManager.play(AudioManager.SoundEffects.BLOOP, randf_range(0.9, 1.1))


static func disappear_animation(from: Node) -> void :
	if not is_instance_valid(_instance) or _instance._last_requested_by != from:
		return

	if _instance._tween and _instance._tween.is_running():
		_instance._tween.stop()

	_instance._tween = _instance.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_instance._tween.parallel().tween_property(_instance, "modulate:a", 0, 0.1)
	_instance._tween.parallel().tween_property(_instance, "_animation_y_addition", 2, 0.1)
	_instance._tween.tween_callback( func() -> void :
		_instance.visible = false
	)


func _enter_tree() -> void :
	Tooltip._instance = self


func _exit_tree() -> void :
	Tooltip._instance = null


func _process(_delta: float) -> void :
	size = get_combined_minimum_size()

	match _anchor_mode:
		AnchorMode.HORIZONTAL:
			if _target_position.x > VIEW_WIDTH / 2:
				global_position.x = _target_position.x - size.x - _margin
			else:
				global_position.x = _target_position.x + _margin

			global_position.y = _target_position.y - size.y / 2 + _animation_y_addition

		AnchorMode.VERTICAL:
			global_position.x = _target_position.x - size.x / 2

			if _target_position.y > VIEW_HEIGHT / 2:
				global_position.y = _target_position.y - size.y - _margin
			else:
				global_position.y = _target_position.y + _margin

			global_position.y += _animation_y_addition
