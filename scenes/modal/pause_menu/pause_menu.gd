class_name PauseMenu extends ModalRect


const OPTIONS_MENU_SCENE: PackedScene = preload("res://scenes/options_menu.tscn")


@onready var resume_button: BouncyButton = $VBoxContainer / ResumeButton
@onready var restart_button: BouncyButton = $VBoxContainer / RestartButton
@onready var options_button: BouncyButton = $VBoxContainer / OptionsButton
@onready var menu_buton: BouncyButton = $VBoxContainer / MenuButton


func _ready() -> void :
	super ()

	Input.joy_connection_changed.connect( func(_device: int, connected: bool):
		if not connected:
			_force_pause()
	)

	resume_button.pressed.connect( func():
		GameManager.paused = false
		#AudioManager.set_music_filter_enabled(GameManager.paused)
		visible = false
	)

	options_button.pressed.connect( func():
		var options: OptionsMenu = OPTIONS_MENU_SCENE.instantiate()
		add_child(options)
		options.focus_on_destroy = options_button
	)

	restart_button.pressed.connect( func():
		GameManager.paused = false
		EventManager.cancel_events()
		GameManager.restart()
	)

	menu_buton.pressed.connect( func():
		GameManager.paused = false
		EventManager.cancel_events()

		#SpeedrunTimerLayer.pause_timer()

		Transition.goto(Transition.Scene.MAIN_MENU, func():
			GameManager.reset_pieces_to_original()
		)
	)

	visibility_changed.connect( func():
		if visible:
			resume_button.grab_focus()
	)


func _unhandled_input(event: InputEvent) -> void :
	if event.is_action_pressed("pause"):
		GameManager.paused = not GameManager.paused
		visible = GameManager.paused

		#AudioManager.set_music_filter_enabled(GameManager.paused)

	if event is InputEventKey and Engine.has_singleton("Steam"):
		if event.pressed and event.keycode == KEY_TAB:
			if Input.is_key_pressed(KEY_SHIFT):
				visible = true

				GameManager.paused = true
				#AudioManager.set_music_filter_enabled(GameManager.paused)


func _force_pause() -> void :
	GameManager.paused = true
	#AudioManager.set_music_filter_enabled(GameManager.paused)
	visible = true
