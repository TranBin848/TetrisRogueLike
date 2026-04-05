class_name OptionsMenu extends ModalRect


@onready var center_container: CenterContainer = $CenterContainer
@onready var general_tab_button: Button = $CenterContainer / VBoxContainer / TabsHBoxContainer / GeneralTabButton
@onready var keyboard_tab_button: Button = $CenterContainer / VBoxContainer / TabsHBoxContainer / KeyboardTabButton
#@onready var general_container: SettingsGeneralVBoxContainer = $CenterContainer / VBoxContainer / PanelContainer / VBoxContainer / GeneralVBoxContainer
@onready var controls_scroll_container: ScrollContainer = $CenterContainer / VBoxContainer / PanelContainer / VBoxContainer / ControlsScrollContainer
#@onready var controls_container: SettingsControlsVBoxContainer = $CenterContainer / VBoxContainer / PanelContainer / VBoxContainer / ControlsScrollContainer / MarginContainer / ControlsVBoxContainer
@onready var reset_controls_button: BouncyButton = %ResetControlsButton
@onready var save_button: BouncyButton = %SaveButton
#@onready var reset_keybindings_confirmation: ResetKeybindingsConfirmation = $ResetKeybindingsConfirmation

var settings: SettingsResource


func _ready() -> void :
	super ()

	load_settings()
	appear_animation()


	general_tab_button.toggled.connect( func(pressed: bool):
		if pressed:
			#AudioManager.play(AudioManager.SoundEffects.BLOOP, randf_range(0.9, 1.1))
			show_general_tab()
	)

	keyboard_tab_button.toggled.connect( func(pressed: bool):
		if pressed:
			#AudioManager.play(AudioManager.SoundEffects.BLOOP, randf_range(0.9, 1.1))
			show_controls_tab()
	)


	save_button.pressed.connect( func() -> void :
		settings.write()
		queue_free()
	)


	#reset_controls_button.pressed.connect( func() -> void :
		#reset_keybindings_confirmation.appear_animation()
	#)


	#reset_keybindings_confirmation.controls_container = controls_container


	show_general_tab()
	save_button.grab_focus()


func load_settings() -> void :
	settings = SettingsResource.load_from_disk()
	#general_container.load_settings(settings)
	#controls_container.load_settings(settings)


func show_general_tab() -> void :
	#general_container.visible = true
	controls_scroll_container.visible = false
	general_tab_button.grab_focus()

	reset_controls_button.visible = false


	#var input_repeat_delay_plus: TextureButton = general_container.get_node("InputRepeatDelayContainer/PlusButton")
	#if input_repeat_delay_plus:
		#save_button.focus_neighbor_top = input_repeat_delay_plus.get_path()


func show_controls_tab() -> void :
	#general_container.visible = false
	controls_scroll_container.visible = true
	keyboard_tab_button.grab_focus()

	reset_controls_button.visible = true


	#var last_button: Button = controls_container.get_last_button()
	#if last_button:
		#save_button.focus_neighbor_top = last_button.get_path()



func _unhandled_input(event: InputEvent) -> void :
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		settings.write()
		queue_free()
		get_viewport().set_input_as_handled()


	if event is InputEventJoypadButton:
		if event.button_index == JOY_BUTTON_LEFT_SHOULDER and event.is_pressed():

			general_tab_button.button_pressed = true
			get_viewport().set_input_as_handled()
		elif event.button_index == JOY_BUTTON_RIGHT_SHOULDER and event.is_pressed():

			keyboard_tab_button.button_pressed = true
			get_viewport().set_input_as_handled()


func _process(_delta: float) -> void :
	if visible:
		center_container.pivot_offset = center_container.size / 2


func appear_animation() -> void :
	visible = true

	center_container.modulate.a = 0.0

	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_callback( func():
		return
		#AudioManager.play(AudioManager.SoundEffects.BLOOP_HIGH, 1.4)
	)

	tween.tween_property(center_container, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(center_container, "scale", Vector2.ONE, 0.3).from(Vector2(1.1, 0.9))
