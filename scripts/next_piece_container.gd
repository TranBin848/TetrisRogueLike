class_name NextPieceContainer extends PanelContainer

const DECK_SCREEN_PACKED_SCENE: PackedScene = preload("res://scenes/modal/current_deck/deck_screen.tscn")
const HOVER_MODULATE: Color = Color(1.2, 1.2, 1.2, 1)
const NEXT_CONTAINER_SIZE: int = 48


var scale_tween: Tween
var deck_screen_instance: DeckScreen = null


@onready var next_container: Control = $VBoxContainer / NextContainer
@onready var piece_renderer: PieceRenderer = $VBoxContainer / NextContainer / PieceRenderer
@onready var eclipse_container: CenterContainer = $VBoxContainer/NextContainer/EclipseContainer
@onready var remaining_count_label: LabelShadowed = $VBoxContainer / RemainingCountLabel
@onready var blink_timer: Timer = $BlinkTimer


func _ready() -> void :
	update_next_display()

	mouse_entered.connect( func() -> void :
		self_modulate = HOVER_MODULATE

		pivot_offset = size / 2

		if scale_tween and scale_tween.is_running():
			scale_tween.stop()

		scale_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		scale_tween.tween_property(self, "scale", Vector2.ONE * 1.05, 0.2)
	)

	mouse_exited.connect( func() -> void :
		self_modulate = Color.WHITE

		if scale_tween and scale_tween.is_running():
			scale_tween.stop()

		scale_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		scale_tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	)

	GameManager.next_piece_calculated.connect( func():
		update_next_display()
	)

	blink_timer.timeout.connect( func():
		next_container.modulate.a = 1.0 - next_container.modulate.a
		remaining_count_label.visible = not remaining_count_label.visible
	)


func _unhandled_input(event: InputEvent) -> void :
	if GameManager.is_game_busy():
		return

	if event.is_action_pressed("user_show_deck"):
		_pressed()


func _gui_input(event: InputEvent) -> void :
	if GameManager.is_game_busy():
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_pressed()


func center_piece(piece_type: PieceRenderer.ShapeType) -> void :
	var bounds: Rect2i = piece_renderer.get_piece_bounds(piece_type, 0)

	if bounds.size == Vector2i.ZERO:
		return

	var piece_pixel_width = bounds.size.x * PieceRenderer.PIECE_SIZE
	var piece_pixel_height = bounds.size.y * PieceRenderer.PIECE_SIZE

	var center_x = (next_container.size.x - piece_pixel_width) / 2.0
	var center_y = (next_container.size.y - piece_pixel_height) / 2.0

	var offset_x = center_x - (bounds.position.x * PieceRenderer.PIECE_SIZE)
	var offset_y = center_y - (bounds.position.y * PieceRenderer.PIECE_SIZE)

	piece_renderer.position = Vector2(offset_x, offset_y)


func update_next_display() -> void :
	if GameManager.current_boss == GameData.BossTypes.ECLIPSE:
		piece_renderer.visible = false
		eclipse_container.visible = true
		remaining_count_label.text = "?/?"
		return
	else:
		eclipse_container.visible = false

	var next_piece_data: Dictionary = GameManager.get_next_piece()
	var remaining_count: int = GameManager.get_remaining_pieces_count()

	if remaining_count == 0 and next_piece_data.is_empty():
		piece_renderer.visible = false
		remaining_count_label.text = tr("EMPTY")
		remaining_count_label.visible = true
		blink_timer.stop()
		return

	if not next_piece_data.is_empty():
		piece_renderer.visible = true
		piece_renderer.set_piece(next_piece_data.shape, 0, false, next_piece_data.type)
		center_piece(next_piece_data.shape)

	remaining_count_label.text = str(remaining_count) + "/" + str(GameManager.get_original_pieces_count())

	if remaining_count <= 3 and blink_timer.is_stopped():
		blink_timer.start()


func _pressed() -> void :
	if is_instance_valid(deck_screen_instance):
		return

	pivot_offset = size / 2

	#AudioManager.play(AudioManager.SoundEffects.DOUBLE_CLICK, randf_range(0.8, 1.2))

	if scale_tween and scale_tween.is_running():
		scale_tween.stop()

	scale_tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", Vector2.ONE, 0.3).from(Vector2.ONE * 0.9)

	deck_screen_instance = DECK_SCREEN_PACKED_SCENE.instantiate()
	GameManager.get_current_scene().get_node("HUD").add_child(deck_screen_instance)
