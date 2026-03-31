class_name SettingsResource extends Resource

const SETTINGS_PATH = "user://settings.tres"

@export var fullscreen: bool = true
@export var bloom: bool = true
@export var music_volume: float = 0.5
@export var effect_volume: float = 0.5
@export var game_speed: float = 1.0
@export var locale: String = OS.get_locale_language()
@export var show_tutorial: bool = true
@export var speedrun_timer_enabled: bool = false
@export var input_repeat_delay: float = 0.15
@export var input_repeat_rate: float = 0.05
@export var soft_drop_rate: float = 0.15
@export var custom_input_map: Dictionary = {}



static var default_input_map: Dictionary = {}

static func load_from_disk() -> SettingsResource:
	if FileAccess.file_exists(SETTINGS_PATH):
		var settings: SettingsResource = ResourceLoader.load(SETTINGS_PATH) as SettingsResource

		settings.save_default_inputs()
		settings.apply_custom_inputs()

		return settings
	else:
		var settings: SettingsResource = SettingsResource.new()
		settings.save_default_inputs()
		return settings

func write() -> void :
	save_current_inputs()
	ResourceSaver.save(self, SETTINGS_PATH)


func save_default_inputs() -> void :

	if default_input_map.is_empty():
		for action_name in InputMap.get_actions():
			if action_name.begins_with("user_"):
				default_input_map[action_name] = {
					"keyboard": null, 
					"joypad": null
				}

				var events: Array[InputEvent] = InputMap.action_get_events(action_name)
				for event in events:
					if event is InputEventKey:
						default_input_map[action_name]["keyboard"] = event.duplicate()
					elif event is InputEventJoypadButton:
						default_input_map[action_name]["joypad"] = event.duplicate()


func save_current_inputs() -> void :

	custom_input_map.clear()

	for action_name in InputMap.get_actions():
		if action_name.begins_with("user_"):
			custom_input_map[action_name] = {
				"keyboard": null, 
				"joypad": null
			}

			var events: Array[InputEvent] = InputMap.action_get_events(action_name)
			for event in events:
				if event is InputEventKey:
					custom_input_map[action_name]["keyboard"] = event.duplicate()
				elif event is InputEventJoypadButton:
					custom_input_map[action_name]["joypad"] = event.duplicate()


func apply_custom_inputs() -> void :

	for action_name in custom_input_map:
		if not InputMap.has_action(action_name):
			continue

		var custom_inputs: Dictionary = custom_input_map[action_name]


		var events: Array[InputEvent] = InputMap.action_get_events(action_name)
		for event in events:
			if event is InputEventKey and custom_inputs.has("keyboard"):
				InputMap.action_erase_event(action_name, event)
			elif event is InputEventJoypadButton and custom_inputs.has("joypad"):
				InputMap.action_erase_event(action_name, event)


		if custom_inputs.get("keyboard") != null:
			InputMap.action_add_event(action_name, custom_inputs["keyboard"])
		if custom_inputs.get("joypad") != null:
			InputMap.action_add_event(action_name, custom_inputs["joypad"])


func restore_default_inputs() -> void :
	for action_name in default_input_map:
		if not InputMap.has_action(action_name):
			continue


		InputMap.action_erase_events(action_name)


		var defaults: Dictionary = default_input_map[action_name]

		if defaults.get("keyboard") != null:
			InputMap.action_add_event(action_name, defaults["keyboard"].duplicate())
		if defaults.get("joypad") != null:
			InputMap.action_add_event(action_name, defaults["joypad"].duplicate())


	custom_input_map.clear()
	write()
