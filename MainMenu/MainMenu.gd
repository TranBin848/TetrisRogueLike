extends Control

@onready var play_button: Button = $CenterContainer/VBoxContainer/ButtonSection/PlayButton
@onready var settings_button : Button = $CenterContainer/VBoxContainer/ButtonSection/SettingsButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/ButtonSection/QuitButton
@onready var falling_blocks: Node2D = $FallingBlocks

const GAME_SCENE = "res://testscenes/tile_map.tscn"
const SETTING_SCENE = "res://scene/ui/Settings.tscn"
const FADE_DURATION: float = 0.4

func _ready() ->void:
	_connect_buttons()
	_spawn_falling_blocks()
	_animate_intro()

func _connect_buttons() -> void:
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_play_pressed() ->void:
	play_button.disabled = true
	_transition_to(GAME_SCENE)

func _on_settings_pressed() -> void:
	_transition_to(SETTING_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _transition_to(scene_path: String) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0,0,0,0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	add_child(overlay)
	
	var tween := create_tween()
	tween.tween_property(overlay , "color:a" , 1.0 , FADE_DURATION)\
	.set_ease(Tween.EASE_IN)
	tween.tween_callback(
		func():get_tree().change_scene_to_file(scene_path)
	)

func _animate_intro() -> void:
	var logo_section = $CenterContainer/VBoxContainer/LogoSection
	var btn_section  = $CenterContainer/VBoxContainer/ButtonSection
	logo_section.modulate.a = 0.0
	btn_section.modulate.a  = 0.0
	var tween := create_tween()
	tween.set_parallel(false)
	tween.tween_property(logo_section, "modulate:a", 1.0, 0.5)\
			.set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.15)
	tween.tween_property(btn_section, "modulate:a", 1.0, 0.4)\
			.set_ease(Tween.EASE_OUT)

const BLOCK_COLORS := [
	Color("#6c5ce7"), Color("#9b8aff"),
	Color("#fd79a8"), Color("#00cec9"), Color("#fdcb6e")
]
func _spawn_falling_blocks() -> void:
	for i in range(12):
		_create_falling_block()

func _create_falling_block() -> void:
	var block := ColorRect.new()
	block.size = Vector2(16, 16) * randf_range(1.0, 2.5)
	block.color = BLOCK_COLORS[randi() % BLOCK_COLORS.size()]
	block.color.a = 0.2

	var start_x := randf() * get_viewport_rect().size.x
	block.position = Vector2(start_x, -40)
	falling_blocks.add_child(block)

	_animate_block(block)

func _animate_block(block: ColorRect) -> void:
	var screen_h   : float = get_viewport_rect().size.y + 60
	var duration   : float = randf_range(5.0, 12.0)
	var start_delay: float = randf_range(0.0, 10.0)

	var tween := create_tween().set_loops()
	tween.tween_interval(start_delay)
	tween.tween_property(block, "position:y", screen_h, duration)\
			.set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		block.position.x = randf() * get_viewport_rect().size.x
		block.position.y = -40.0
	)
