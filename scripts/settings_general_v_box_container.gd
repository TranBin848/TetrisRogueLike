class_name SettingsGeneralVBoxContainer extends VBoxContainer


@onready var fullscreen_toggle_button: PixelToggleButton = %FullscreenToggleButton
@onready var bloom_toggle_button: PixelToggleButton = %BloomToggleButton
@onready var speedrun_toggle_button: PixelToggleButton = %SpeedrunToggleButton
@onready var music_slider: HSlider = %MusicSlider
@onready var effect_slider: HSlider = %EffectSlider
@onready var previous_language_button: BouncyTextureButton = %PreviousLanguageButton
@onready var next_language_button: BouncyTextureButton = %NextLanguageButton
@onready var language_value_label: LabelShadowed = %LanguageValueLabel
@onready var previous_game_speed_button: BouncyTextureButton = %PreviousGameSpeedButton
@onready var next_game_speed_button: BouncyTextureButton = %NextGameSpeedButton
@onready var game_speed_value_label: LabelShadowed = %GameSpeedValueLabel

@onready var input_repeat_rate_minus_button: BouncyTextureButton = $InputRepeatRateContainer / MinusButton
@onready var input_repeat_rate_plus_button: BouncyTextureButton = $InputRepeatRateContainer / PlusButton
@onready var input_repeat_rate_value_label: LabelShadowed = $InputRepeatRateContainer / ValueLabel

@onready var input_repeat_delay_minus_button: BouncyTextureButton = $InputRepeatDelayContainer / MinusButton
@onready var input_repeat_delay_plus_button: BouncyTextureButton = $InputRepeatDelayContainer / PlusButton
@onready var input_repeat_delay_value_label: LabelShadowed = $InputRepeatDelayContainer / ValueLabel

@onready var soft_drop_rate_minus_button: BouncyTextureButton = $SoftDropRateContainer / MinusButton
@onready var soft_drop_rate_plus_button: BouncyTextureButton = $SoftDropRateContainer / PlusButton
@onready var soft_drop_rate_value_label: LabelShadowed = $SoftDropRateContainer / ValueLabel

var settings: SettingsResource
var available_locales: Array[String] = ["en", "pt", "es", "de", "fr", "pl", "ru", "it", "tr", "zh", "ko", "ja"]
var current_locale_index: int = 0
var available_game_speeds: Array[float] = [1.0, 1.5, 2.0]
var current_game_speed_index: int = 0

const MIN_INPUT_REPEAT_RATE: float = 0.01
const MAX_INPUT_REPEAT_RATE: float = 0.2
const INPUT_REPEAT_RATE_STEP: float = 0.01

const MIN_INPUT_REPEAT_DELAY: float = 0.05
const MAX_INPUT_REPEAT_DELAY: float = 0.5
const INPUT_REPEAT_DELAY_STEP: float = 0.01

const MIN_SOFT_DROP_DELAY: float = 0.01
const MAX_SOFT_DROP_DELAY: float = 0.2
const SOFT_DROP_DELAY_STEP: float = 0.01


func _ready() -> void :
	fullscreen_toggle_button.toggled.connect( func(pressed: bool):
		settings.fullscreen = pressed
		if pressed:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	)

	bloom_toggle_button.toggled.connect( func(pressed: bool):
		settings.bloom = pressed
		VisualEffects.enabled = pressed
	)

	speedrun_toggle_button.toggled.connect( func(pressed: bool):
		settings.speedrun_timer_enabled = pressed
		if pressed:
			SpeedrunTimerLayer.activate()
		else:
			SpeedrunTimerLayer.deactivate()
	)

	music_slider.value_changed.connect( func(value: float):
		settings.music_volume = value
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
	)

	effect_slider.value_changed.connect( func(value: float):
		settings.effect_volume = value
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"), linear_to_db(value))
	)

	# effect_slider.gui_input.connect( func(event: InputEvent):
	#     if event is InputEventMouseButton and event.is_released():
	#         AudioManager.play(AudioManager.SoundEffects.SINGLE_CLICK_1, 1.0)
	# )

	previous_language_button.pressed.connect( func():
		current_locale_index = (current_locale_index - 1) % available_locales.size()
		if current_locale_index < 0:
			current_locale_index = available_locales.size() - 1
		settings.locale = available_locales[current_locale_index]
		TranslationServer.set_locale(settings.locale)
	)

	next_language_button.pressed.connect( func():
		current_locale_index = (current_locale_index + 1) % available_locales.size()
		settings.locale = available_locales[current_locale_index]
		TranslationServer.set_locale(settings.locale)
	)

	previous_game_speed_button.pressed.connect( func():
		current_game_speed_index = (current_game_speed_index - 1) % available_game_speeds.size()
		if current_game_speed_index < 0:
			current_game_speed_index = available_game_speeds.size() - 1
		settings.game_speed = available_game_speeds[current_game_speed_index]
		GameManager.timescale = settings.game_speed
		update_game_speed_label()
	)

	next_game_speed_button.pressed.connect( func():
		current_game_speed_index = (current_game_speed_index + 1) % available_game_speeds.size()
		settings.game_speed = available_game_speeds[current_game_speed_index]
		GameManager.timescale = settings.game_speed
		update_game_speed_label()
	)

	input_repeat_rate_minus_button.pressed.connect( func():
		settings.input_repeat_rate = clampf(settings.input_repeat_rate - INPUT_REPEAT_RATE_STEP, MIN_INPUT_REPEAT_RATE, MAX_INPUT_REPEAT_RATE)
		update_input_repeat_rate_label()
	)

	input_repeat_rate_plus_button.pressed.connect( func():
		settings.input_repeat_rate = clampf(settings.input_repeat_rate + INPUT_REPEAT_RATE_STEP, MIN_INPUT_REPEAT_RATE, MAX_INPUT_REPEAT_RATE)
		update_input_repeat_rate_label()
	)

	input_repeat_delay_minus_button.pressed.connect( func():
		settings.input_repeat_delay = clampf(settings.input_repeat_delay - INPUT_REPEAT_DELAY_STEP, MIN_INPUT_REPEAT_DELAY, MAX_INPUT_REPEAT_DELAY)
		update_input_repeat_delay_label()
	)

	input_repeat_delay_plus_button.pressed.connect( func():
		settings.input_repeat_delay = clampf(settings.input_repeat_delay + INPUT_REPEAT_DELAY_STEP, MIN_INPUT_REPEAT_DELAY, MAX_INPUT_REPEAT_DELAY)
		update_input_repeat_delay_label()
	)

	soft_drop_rate_minus_button.pressed.connect( func():
		settings.soft_drop_rate = clampf(settings.soft_drop_rate - SOFT_DROP_DELAY_STEP, MIN_SOFT_DROP_DELAY, MAX_SOFT_DROP_DELAY)
		update_soft_drop_rate_label()
	)

	soft_drop_rate_plus_button.pressed.connect( func():
		settings.soft_drop_rate = clampf(settings.soft_drop_rate + SOFT_DROP_DELAY_STEP, MIN_SOFT_DROP_DELAY, MAX_SOFT_DROP_DELAY)
		update_soft_drop_rate_label()
	)


func load_settings(settings_resource: SettingsResource) -> void :
	settings = settings_resource
	apply_settings_to_ui()


func apply_settings_to_ui() -> void :
	fullscreen_toggle_button.button_pressed = settings.fullscreen
	bloom_toggle_button.button_pressed = settings.bloom
	speedrun_toggle_button.button_pressed = settings.speedrun_timer_enabled
	music_slider.value = settings.music_volume
	effect_slider.value = settings.effect_volume

	current_locale_index = available_locales.find(settings.locale)
	if current_locale_index == -1:
		current_locale_index = 0

	current_game_speed_index = available_game_speeds.find(settings.game_speed)
	if current_game_speed_index == -1:
		current_game_speed_index = 0

	update_game_speed_label()
	update_input_repeat_rate_label()
	update_input_repeat_delay_label()
	update_soft_drop_rate_label()


func update_game_speed_label() -> void :
	var speed_text: String = "%.1fx" % settings.game_speed
	game_speed_value_label.text = speed_text


func update_input_repeat_rate_label() -> void :
	var rate_text: String = "%.2fs" % settings.input_repeat_rate
	input_repeat_rate_value_label.text = rate_text


func update_input_repeat_delay_label() -> void :
	var delay_text: String = "%.2fs" % settings.input_repeat_delay
	input_repeat_delay_value_label.text = delay_text


func update_soft_drop_rate_label() -> void :
	var rate_text: String = "%.2fs" % settings.soft_drop_rate
	soft_drop_rate_value_label.text = rate_text
