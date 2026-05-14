class_name VisualEffects extends CanvasLayer


static var _self: VisualEffects = null

static var enabled: bool = true:
    set(value):
        enabled = value

        if is_instance_valid(_self) and is_instance_valid(_self.crt_effect):
            _self.crt_effect.visible = value


@onready var crt_effect: ColorRect = $CRTEffectOverlay


func _enter_tree() -> void :
    VisualEffects._self = self


func _exit_tree() -> void :
    VisualEffects._self = null


func _ready():
    crt_effect.visible = VisualEffects.enabled

    get_viewport().size_changed.connect(_on_viewport_size_changed)
    _update_crt_resolution()


func _on_viewport_size_changed():
    _update_crt_resolution()


func _update_crt_resolution():
    if crt_effect and crt_effect.material:
        var window_size = DisplayServer.window_get_size()
        crt_effect.material.set_shader_parameter("resolution", window_size / 4)
