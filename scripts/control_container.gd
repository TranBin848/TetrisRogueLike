class_name ControlContainer extends HBoxContainer

const KEYBOARD_BUTTON_STYLE_NORMAL: StyleBoxTexture = preload("res://resources/settings/keyboard_button_normal.tres")
const KEYBOARD_BUTTON_STYLE_PRESSED: StyleBoxTexture = preload("res://resources/settings/keyboard_button_pressed.tres")
const KEYBOARD_BUTTON_STYLE_HOVER: StyleBoxTexture = preload("res://resources/settings/keyboard_button_hover.tres")

const ICON_ARROW_UP: CompressedTexture2D = preload("res://images/key_arrow_up.png")
const ICON_ARROW_DOWN: CompressedTexture2D = preload("res://images/key_arrow_down.png")
const ICON_ARROW_RIGHT: CompressedTexture2D = preload("res://images/key_arrow_right.png")
const ICON_ARROW_LEFT: CompressedTexture2D = preload("res://images/key_arrow_left.png")
const ICON_SPACEBAR: CompressedTexture2D = preload("res://images/key_space.png")

signal input_remapped(action_name: String)
signal listening_started()
signal listening_stopped()

@onready var title_label: LabelShadowed = $Title
@onready var input_button: Button = $InputButton

var input_action_name: String = "":
	set(value):
		input_action_name = value
		if is_node_ready():
			_update_display()

var is_listening_for_input: bool = false
var blink_tween: Tween
var _last_input_was_gamepad: bool = false


const FORBIDDEN_KEYS: Array[Key] = [
	KEY_ESCAPE, 
	KEY_F11, 
	KEY_PRINT, 
	KEY_PAUSE, 
]

const FORBIDDEN_JOYPAD_BUTTONS: Array[int] = [
	JOY_BUTTON_START, 
	JOY_BUTTON_BACK
]


func _ready() -> void :

	_last_input_was_gamepad = GameManager.is_gamepad_connected
	_update_display()


	input_button.pressed.connect(_start_listening_for_input)


	Input.joy_connection_changed.connect( func(_device: int, connected: bool) -> void :

		if connected:
			_last_input_was_gamepad = true
			_update_display()
	)

	GameManager.input_remapped.connect( func() -> void :
		_update_display()
	)


func _update_display() -> void :
	if input_action_name.is_empty():
		return


	title_label.text = "INPUT_" + input_action_name.to_upper()


	var input_events: Array[InputEvent] = InputMap.action_get_events(input_action_name)

	if _last_input_was_gamepad:

		var joypad_event: InputEventJoypadButton = null
		for event in input_events:
			if event is InputEventJoypadButton:
				joypad_event = event
				break

		if joypad_event:

			input_button.flat = true
			input_button.text = ""
			#input_button.icon = Utils.get_button_texture_based_on_controller(joypad_event.button_index)
		else:

			input_button.flat = true
			input_button.text = ""
			#input_button.icon = Utils.UNKNOWN_BUTTON_TEXTURE
	else:

		_show_keyboard_input(input_events)


func _show_keyboard_input(input_events: Array[InputEvent]) -> void :

	var keyboard_event: InputEventKey = null
	for event in input_events:
		if event is InputEventKey:
			keyboard_event = event
			break

	if keyboard_event:
		input_button.flat = false


		var key_icon: CompressedTexture2D = _get_key_icon(keyboard_event.physical_keycode)

		if key_icon:

			input_button.icon = key_icon
			input_button.text = ""
		else:

			input_button.icon = null
			input_button.text = OS.get_keycode_string(keyboard_event.physical_keycode)
	else:

		input_button.flat = false
		input_button.icon = null
		input_button.text = "?"


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


func _start_listening_for_input() -> void :
	if is_listening_for_input:
		return

	is_listening_for_input = true
	_start_blink_animation()


	input_button.disabled = true


	listening_started.emit()


func _stop_listening_for_input() -> void :
	is_listening_for_input = false
	_stop_blink_animation()


	input_button.disabled = false


	listening_stopped.emit()


func cancel_listening() -> void :

	if is_listening_for_input:
		_stop_listening_for_input()


func _start_blink_animation() -> void :
	_stop_blink_animation()

	blink_tween = create_tween().set_loops()
	blink_tween.tween_callback( func():
		input_button.modulate.a = 0.0
	)
	blink_tween.tween_interval(0.2)
	blink_tween.tween_callback( func():
		input_button.modulate.a = 1.0
	)
	blink_tween.tween_interval(0.2)


func _stop_blink_animation() -> void :
	if blink_tween:
		blink_tween.kill()
		blink_tween = null

	input_button.modulate.a = 1.0


func _input(event: InputEvent) -> void :

	if not is_listening_for_input:
		if event is InputEventJoypadButton:
			_last_input_was_gamepad = true
			_update_display()
		elif event is InputEventKey:
			_last_input_was_gamepad = false
			_update_display()
		return


	if event is InputEventKey and event.is_pressed() and not event.is_echo():

		if event.keycode == KEY_ESCAPE:
			_stop_listening_for_input()
			get_viewport().set_input_as_handled()
			return


		if event.keycode in FORBIDDEN_KEYS or event.physical_keycode in FORBIDDEN_KEYS:
			_stop_listening_for_input()
			get_viewport().set_input_as_handled()
			return


		_remap_input(event)
		get_viewport().set_input_as_handled()


	elif event is InputEventJoypadButton and event.is_pressed():

		if event.button_index in FORBIDDEN_JOYPAD_BUTTONS:
			_stop_listening_for_input()
			get_viewport().set_input_as_handled()
			return

		_remap_input(event)
		get_viewport().set_input_as_handled()


func _remap_input(new_event: InputEvent) -> void :
	if input_action_name.is_empty():
		return


	for action in InputMap.get_actions():
		if not action.begins_with("user_"):
			continue

		if action == input_action_name:
			continue

		var other_action_events_to_remove: Array[InputEvent] = []
		for existing_event in InputMap.action_get_events(action):
			if _events_match(existing_event, new_event):
				other_action_events_to_remove.append(existing_event)

		for event_to_remove in other_action_events_to_remove:
			InputMap.action_erase_event(action, event_to_remove)


	var current_action_events_to_remove: Array[InputEvent] = []
	for existing_event in InputMap.action_get_events(input_action_name):
		if (new_event is InputEventKey and existing_event is InputEventKey) or \
(new_event is InputEventJoypadButton and existing_event is InputEventJoypadButton):
			current_action_events_to_remove.append(existing_event)

	for event_to_remove in current_action_events_to_remove:
		InputMap.action_erase_event(input_action_name, event_to_remove)


	InputMap.action_add_event(input_action_name, new_event)


	_update_display()
	_stop_listening_for_input()


	input_remapped.emit(input_action_name)
	GameManager.input_remapped.emit()


func _events_match(event1: InputEvent, event2: InputEvent) -> bool:
	if event1 is InputEventKey and event2 is InputEventKey:
		return event1.physical_keycode == event2.physical_keycode
	elif event1 is InputEventJoypadButton and event2 is InputEventJoypadButton:
		return event1.button_index == event2.button_index
	return false
