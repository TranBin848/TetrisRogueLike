class_name HoldBackgroundPanel extends PanelContainer


var movement_tween: Tween

@onready var piece_container: Control = %PieceContainer
@onready var empty_texture_rect: TextureRect = %EmptyTextureRect
@onready var eclipse_container: CenterContainer = %EclipseContainer
@onready var eclipse_texture_rect: TextureRect = %EclipseContainer / EclipseTextureRect
@onready var piece_renderer: PieceRenderer = %PieceRenderer


func _ready() -> void :
	modulate.a = 1

	if GameManager.current_boss == GameData.BossTypes.THIEF:
		modulate.a = 0.5

	update_hold_display()

	GameManager.hold_piece_changed.connect( func():
		update_hold_display()
		floating_animation()

	)


func floating_animation() -> void :
	if movement_tween and movement_tween.is_running():
		return

	movement_tween = create_tween().set_loops().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	movement_tween.tween_property(self, "position:y", position.y + 2, 1.0)
	movement_tween.tween_property(self, "position:y", position.y - 2, 1.0)


func center_piece(piece_type: PieceRenderer.ShapeType) -> void :
	var bounds: Rect2i = piece_renderer.get_piece_bounds(piece_type, 0)

	if bounds.size == Vector2i.ZERO:
		return

	var piece_pixel_width = bounds.size.x * PieceRenderer.PIECE_SIZE * piece_renderer.scale.x
	var piece_pixel_height = bounds.size.y * PieceRenderer.PIECE_SIZE * piece_renderer.scale.y

	var center_x = (piece_container.size.x - piece_pixel_width) / 2.0
	var center_y = (piece_container.size.y - piece_pixel_height) / 2.0

	var offset_x = center_x - (bounds.position.x * PieceRenderer.PIECE_SIZE * piece_renderer.scale.x)
	var offset_y = center_y - (bounds.position.y * PieceRenderer.PIECE_SIZE * piece_renderer.scale.y)

	piece_renderer.position = Vector2(offset_x, offset_y)


func update_hold_display() -> void :
	if GameManager.current_boss == GameData.BossTypes.ECLIPSE:
		piece_renderer.visible = false
		empty_texture_rect.visible = false
		eclipse_container.visible = true

		if not GameManager.hold_piece_data.is_empty():
			var scale_tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			scale_tween.tween_property(self, "scale", Vector2.ONE, 0.5 / GameManager.timescale).from(Vector2.ONE * 1.2)

		return
	else:
		eclipse_container.visible = false


	if GameManager.hold_piece_data.is_empty():
		piece_renderer.visible = false
		empty_texture_rect.visible = true
	else:
		piece_renderer.visible = true
		empty_texture_rect.visible = false

		var held_piece_shape: PieceRenderer.ShapeType = GameManager.hold_piece_data.shape
		var held_piece_type: String = GameManager.hold_piece_data.type

		piece_renderer.set_piece(held_piece_shape, 0, true, held_piece_type)
		center_piece(held_piece_shape)

		var scale_tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		scale_tween.tween_property(self, "scale", Vector2.ONE, 0.5 / GameManager.timescale).from(Vector2.ONE * 1.2)
