class_name LevelSelectionSquareRenderer extends Node2D


const SPAWN_DISTANCE: float = 64.0
const ARROW_DISTANCE: float = 32.0
const ARROW_DEFAULT_TEXTURE: CompressedTexture2D = preload("res://images/level_selection/arrow_default.png")
const ARROW_PASSED_TEXTURE: CompressedTexture2D = preload("res://images/level_selection/arrow_light.png")


var current_square: LevelSelectionSquare = null:
	set(value):
		current_square = value

		if is_instance_valid(current_square):
			GameManager.current_boss = current_square.boss_type


@onready var camera: GameCamera = GameManager.get_unique_node("GameCamera")
@onready var information_panel_anchor: Control = GameManager.get_unique_node("InformationPanelAnchor")
@onready var round_information_panel: RoundInformationPanel = GameManager.get_unique_node("RoundInformationPanel")
@onready var boss_information_panel: BossInformationPanel = GameManager.get_unique_node("BossInformationPanel")


func _ready() -> void :
	boss_information_panel.visible = false
	round_information_panel.visible = false

	await get_tree().process_frame

	var squares: Array[LevelSelectionSquare] = []
	var previous_square: LevelSelectionSquare = null



	var current: int = GameManager.current_round
	var start_round: int = max(1, current - 4)
	var end_round: int = current + 4


	if GameManager.is_demo_build:
		end_round = min(end_round, GameManager.DEMO_LAST_ROUND)

	var rounds_to_display: int = end_round - start_round + 1
	print("Creating ", rounds_to_display, " squares for rounds ", start_round, "-", end_round, " (Demo mode: ", GameManager.is_demo_build, ")")


	for i in range(rounds_to_display):
		var round_num: int = start_round + i
		var square: LevelSelectionSquare = LevelSelectionSquare.create(self, round_num)
		squares.append(square)

		square.position.x = i * SPAWN_DISTANCE

		if round_num < current - 1:
			square.modulate.a = 0.3
		elif round_num == current - 1:
			previous_square = square
		elif round_num == current:
			current_square = square


		if i < rounds_to_display - 1:
			var arrow_sprite: Sprite2D = Sprite2D.new()
			add_child(arrow_sprite)

			if round_num < current:
				arrow_sprite.texture = ARROW_PASSED_TEXTURE
			else:
				arrow_sprite.texture = ARROW_DEFAULT_TEXTURE

			arrow_sprite.position.x = square.position.x + ARROW_DISTANCE

	if previous_square != null and current_square != null:
		camera.global_position = previous_square.global_position

		await get_tree().create_timer(1.0 / GameManager.timescale).timeout

		#AudioManager.play(AudioManager.SoundEffects.BLOOP, 1.0)

		var speed: float = GameManager.timescale
		var modulate_tween: Tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		modulate_tween.tween_property(previous_square, "modulate:a", 0.3, 0.3 / speed)

		await modulate_tween.finished

		var camera_tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		camera_tween.tween_property(camera, "global_position", current_square.global_position, 0.75 / speed)
		camera_tween.tween_callback( func():
			#AudioManager.play(AudioManager.SoundEffects.PERK, 0.65 + (current_square.round_index * 0.05))
			#AudioManager.play(AudioManager.SoundEffects.BLOOP, 1.0)
			current_square.current_round_indicator.visible = true

			round_information_panel.appear_animation()

			if current_square.boss_type != GameData.BossTypes.NONE:
				boss_information_panel.appear_animation()
		)
		camera_tween.tween_property(current_square, "scale", Vector2.ONE, 0.5 / speed).from(Vector2.ONE * 1.2)

	elif current_square != null:
		camera.global_position = current_square.global_position

		await get_tree().create_timer(1.0 / GameManager.timescale).timeout

		#AudioManager.play(AudioManager.SoundEffects.PERK, 0.65 + (current_square.round_index * 0.05))
		#AudioManager.play(AudioManager.SoundEffects.BLOOP, 1.0)
		current_square.current_round_indicator.visible = true

		round_information_panel.appear_animation()

		if current_square.boss_type != GameData.BossTypes.NONE:
			boss_information_panel.appear_animation()

		var speed: float = GameManager.timescale
		var scale_tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		scale_tween.tween_property(current_square, "scale", Vector2.ONE, 0.5 / speed).from(Vector2.ONE * 1.2)


func _process(_delta: float) -> void :
	information_panel_anchor.global_position = current_square.global_position
