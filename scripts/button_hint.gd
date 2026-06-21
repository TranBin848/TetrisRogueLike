class_name ButtonHint extends Control

const ICON_ARROW_UP: CompressedTexture2D = preload("res://images/key_arrow_up.png")
const ICON_ARROW_DOWN: CompressedTexture2D = preload("res://images/key_arrow_down.png")
const ICON_ARROW_RIGHT: CompressedTexture2D = preload("res://images/key_arrow_right.png")
const ICON_ARROW_LEFT: CompressedTexture2D = preload("res://images/key_arrow_left.png")
const ICON_SPACEBAR: CompressedTexture2D = preload("res://images/key_space.png")

@onready var keyboard_hint_panel: PanelContainer = $KeyboardHintPanelContainer
@onready var key_hint_label: LabelShadowed = $KeyboardHintPanelContainer / KeyHintLabel
@onready var key_icon_texture: TextureRect = $KeyboardHintPanelContainer / KeyIconTexture
@onready var controller_texture: TextureRect = $TextureRect

@export var input_action_name: String = "":
	set(value):
		input_action_name = value
		if is_node_ready():
			_update_display()

var _last_input_was_gamepad: bool = false


func _ready() -> void :

	_last_input_was_gamepad = GameManager.is_gamepad_connected
	_update_display()


	Input.joy_connection_changed.connect( func(_device: int, connected: bool) -> void :

		if connected:
			_last_input_was_gamepad = true
			_update_display()
	)

	GameManager.input_remapped.connect( func() -> void :
		_update_display()
	)


func _input(event: InputEvent) -> void :
	if event is InputEventJoypadButton:
		_last_input_was_gamepad = true
		_update_display()
	elif event is InputEventKey:
		_last_input_was_gamepad = false
		_update_display()


func _update_display() -> void :
	if input_action_name.is_empty():
		return


	var input_events: Array[InputEvent] = InputMap.action_get_events(input_action_name)

	if _last_input_was_gamepad:

		var joypad_event: InputEventJoypadButton = null
		for event in input_events:
			if event is InputEventJoypadButton:
				joypad_event = event
				break

		if joypad_event:

			keyboard_hint_panel.visible = false
			controller_texture.visible = true
			


			if _is_shoulder_button(joypad_event.button_index):
				custom_minimum_size = Vector2(22, 14)
			else:
				custom_minimum_size = Vector2(14, 14)
		else:

			keyboard_hint_panel.visible = false
			controller_texture.visible = true
		   
	else:

		_show_keyboard_input(input_events)


func _show_keyboard_input(input_events: Array[InputEvent]) -> void :

	var keyboard_event: InputEventKey = null
	for event in input_events:
		if event is InputEventKey:
			keyboard_event = event
			break

	if keyboard_event:
		keyboard_hint_panel.visible = true
		controller_texture.visible = false


		var key_icon: CompressedTexture2D = _get_key_icon(keyboard_event.physical_keycode)

		if key_icon:


			key_icon_texture.visible = true
			key_icon_texture.texture = key_icon
			key_hint_label.visible = false
			key_hint_label.text = OS.get_keycode_string(keyboard_event.physical_keycode)
		else:

			key_icon_texture.visible = false
			key_hint_label.visible = true
			key_hint_label.text = OS.get_keycode_string(keyboard_event.physical_keycode)
	else:

		keyboard_hint_panel.visible = true
		controller_texture.visible = false
		key_hint_label.text = "?"


func _get_key_icon(keycode: Key) -> CompressedTexture2D:
	match keycode:
		KEY_UP:
			return ICON_ARROW_UP
		KEY_DOWN:
			return ICON_ARROW_DOWN
		KEY_LEFT:
			return ICON_ARROW_LEFT
		KEY_RIGHT:
			return ICON_ARROW_RIGHT
		KEY_SPACE:
			return ICON_SPACEBAR
		_:
			return null


func _is_shoulder_button(button_index: JoyButton) -> bool:

	return button_index in [
		JOY_BUTTON_LEFT_SHOULDER, 
		JOY_BUTTON_RIGHT_SHOULDER, 
		JOY_BUTTON_LEFT_STICK, 
		JOY_BUTTON_RIGHT_STICK
	]
