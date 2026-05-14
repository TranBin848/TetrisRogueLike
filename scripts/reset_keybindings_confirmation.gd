class_name ResetKeybindingsConfirmation extends ModalRect


@onready var panel_container: PanelContainer = $CenterContainer / PanelContainer
@onready var yes_button: BouncyButton = %YesButton
@onready var no_button: BouncyButton = %NoButton

var controls_container: SettingsControlsVBoxContainer


func _ready() -> void :

    visible = false

    yes_button.pressed.connect( func() -> void :
        if not is_instance_valid(controls_container):
            return

        controls_container.restore_defaults()
        visible = false
    )

    no_button.pressed.connect( func() -> void :
        visible = false
    )

    super ()


func _process(_delta: float) -> void :
    if visible:
        panel_container.pivot_offset = panel_container.size / 2


func appear_animation() -> void :
    visible = true

    panel_container.modulate.a = 0.0
    no_button.grab_focus()

    var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

    # tween.tween_callback( func() -> void :
    #     AudioManager.play(AudioManager.SoundEffects.BLOOP_HIGH, 1.4)
    # )

    tween.tween_property(panel_container, "modulate:a", 1.0, 0.2)
    tween.parallel().tween_property(panel_container, "scale", Vector2.ONE, 0.3).from(Vector2(1.1, 0.9))
