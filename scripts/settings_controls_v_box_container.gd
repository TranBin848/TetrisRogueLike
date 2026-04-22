class_name SettingsControlsVBoxContainer extends VBoxContainer

const CONTROL_CONTAINER_SCENE: PackedScene = preload("res://scenes/ui/control_container.tscn")


var settings: SettingsResource
var currently_listening_container: ControlContainer = null


func _ready() -> void :
    _populate_controls()


func _populate_controls() -> void :

    var input_actions: Array[StringName] = []

    for action_name in InputMap.get_actions():
        if action_name.begins_with("user_"):
            input_actions.append(action_name)


    input_actions.sort_custom( func(a: StringName, b: StringName) -> bool:
        var a_key: String = "INPUT_" + String(a).to_upper()
        var b_key: String = "INPUT_" + String(b).to_upper()
        var a_translated: String = tr(a_key)
        var b_translated: String = tr(b_key)
        return a_translated.naturalnocasecmp_to(b_translated) < 0
    )


    for action_name in input_actions:
        var control_container: ControlContainer = CONTROL_CONTAINER_SCENE.instantiate()
        add_child(control_container)
        control_container.input_action_name = action_name


        control_container.input_remapped.connect(_on_input_remapped)


        control_container.listening_started.connect(_on_container_listening_started.bind(control_container))
        control_container.listening_stopped.connect(_on_container_listening_stopped.bind(control_container))


func load_settings(settings_resource: SettingsResource) -> void :
    settings = settings_resource
    apply_settings_to_ui()


func apply_settings_to_ui() -> void :
    pass


func get_last_button() -> Button:

    if get_child_count() > 0:
        var last_child: ControlContainer = get_child(-1) as ControlContainer
        if last_child:
            return last_child.input_button
    return null


func _on_input_remapped(_action_name: String) -> void :


    for child in get_children():
        var control_container: ControlContainer = child as ControlContainer
        if control_container:
            control_container._update_display()


func restore_defaults() -> void :

    if settings:
        settings.restore_default_inputs()


        for child in get_children():
            var control_container: ControlContainer = child as ControlContainer
            if control_container:
                control_container._update_display()


func _on_container_listening_started(container: ControlContainer) -> void :

    if currently_listening_container and currently_listening_container != container:
        currently_listening_container.cancel_listening()

    currently_listening_container = container


func _on_container_listening_stopped(container: ControlContainer) -> void :
    if currently_listening_container == container:
        currently_listening_container = null
