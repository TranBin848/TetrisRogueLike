class_name Tutorial extends ColorRect


const LAST_INDEX: int = 8
const PAUSE_MENU_SCENE: PackedScene = preload("res://scenes/modal/pause_menu/pause_menu.tscn")


var current_step: int = 0
var data: Array[Dictionary] = []
var positions: Array[Vector2] = [
	Vector2(240, 135), 
	Vector2(126, 150), 
	Vector2(240, 135), 
	Vector2(350, 140), 
	Vector2(320, 187), 
	Vector2(126, 150), 
	Vector2(240, 135), 
	Vector2(112, 191),
	Vector2(240, 135)
]


var balloon_tween: Tween
var button_tween: Tween

var current_highlighted_node: CanvasItem = null
var current_highlighted_previous_z_index: int = 0

var highlighted_node_list: Array[String] = [
	"", 
	"../MainMarginContainer/MainHBoxContainer/LeftContainer/ScoreBackgroundPanel", 
	"", 
	"../MainMarginContainer/MainHBoxContainer/RightContainer/NextPieceContainer", 
	"../MainMarginContainer/MainHBoxContainer/RightContainer/HoldBackgroundPanel", 
	"../MainMarginContainer/MainHBoxContainer/LeftContainer/PerkPanel", 
	"", 
	"../MainMarginContainer/MainHBoxContainer/LeftContainer/RoundTimerPanel",
	""
]

@onready var anchor: CenterContainer = $CenterContainer
@onready var talk_balloon_panel: PanelContainer = $CenterContainer / VBoxContainer / TalkBalloon
@onready var content_label: RichTextLabelShadowed = $CenterContainer / VBoxContainer / TalkBalloon / ContentLabel
@onready var buttons_container: VBoxContainer = $CenterContainer / VBoxContainer / TalkBalloon / ButtonsContainer
@onready var continue_button: BouncyButton = $CenterContainer / VBoxContainer / ContinueButton


func _ready() -> void :
	get_viewport().size_changed.connect(_resync_to_viewport)
	_resync_to_viewport()

	GameManager.paused = true
	continue_button.grab_focus()

	visible = true
	anchor.modulate.a = 0

	for i in LAST_INDEX + 1:
		var tutorial_text: String = GameManager.replace_tags(tr("TUTORIAL_%d" % i))

		data.append({
			"text": tutorial_text
		})

	continue_button.pressed.connect( func() -> void :
		if current_step == LAST_INDEX:
			_destroy()
			return

		current_step += 1
		_update_content()
	)

	await get_tree().create_timer(1.5).timeout

	anchor.modulate.a = 1
	content_label.visible_ratio = 0.1

	_update_content()


func _resync_to_viewport() -> void :
	var vp_size: Vector2 = get_viewport_rect().size
	size = vp_size
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam:
		global_position = cam.get_screen_center_position() - vp_size / 2
	else:
		global_position = Vector2.ZERO


func _destroy() -> void :
	var pause_menu: PauseMenu = PAUSE_MENU_SCENE.instantiate()
	var hud_node = GameManager.get_current_scene().get_node("HUD") if GameManager.get_current_scene().has_node("HUD") else GameManager.get_current_scene().get_node("OverlayHUD")
	hud_node.add_child.call_deferred(pause_menu)
	pause_menu.visible = false

	GameManager.paused = false
	queue_free()


func _update_content() -> void :
	anchor.global_position = positions[current_step]
	content_label.text = data[current_step].text


	if current_step == LAST_INDEX:
		content_label.visible = false
		buttons_container.visible = true
	else:
		content_label.visible = true
		buttons_container.visible = false

	if is_instance_valid(current_highlighted_node):
		current_highlighted_node.z_index = current_highlighted_previous_z_index
		current_highlighted_node = null

	if highlighted_node_list.size() > current_step and highlighted_node_list[current_step] != "":
		var target_node = get_node_or_null(highlighted_node_list[current_step])
		if is_instance_valid(target_node) and target_node is CanvasItem:
			current_highlighted_node = target_node
			current_highlighted_previous_z_index = current_highlighted_node.z_index
			current_highlighted_node.z_index = 20

	continue_button.modulate.a = 0
	continue_button.disabled = true

	await get_tree().process_frame

	talk_balloon_panel.pivot_offset = talk_balloon_panel.size / 2

	if button_tween and button_tween.is_valid(): button_tween.kill()
	if balloon_tween and balloon_tween.is_valid(): balloon_tween.kill()

	balloon_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	balloon_tween.tween_property(talk_balloon_panel, "scale", Vector2.ONE, 0.3).from(Vector2(1.2, 0.8))

	balloon_tween = balloon_tween.set_trans(Tween.TRANS_LINEAR)
	balloon_tween.parallel().tween_property(content_label, "visible_ratio", 1.0, 1.5).from(0.1)

	await get_tree().create_timer(1.8).timeout

	continue_button.disabled = false

	button_tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	button_tween.tween_property(continue_button, "modulate:a", 1, 0.2)
	button_tween.set_trans(Tween.TRANS_BACK)
	button_tween.parallel().tween_property(continue_button, "position:y", continue_button.position.y, 0.4).from(continue_button.position.y - 8)
