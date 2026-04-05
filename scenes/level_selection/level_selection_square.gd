class_name LevelSelectionSquare extends Sprite2D


const ROUND_TEXTURE: CompressedTexture2D = preload("res://images/level_selection/round.png")
const ROUND_PASSED_TEXTURE: CompressedTexture2D = preload("res://images/level_selection/round_passed.png")
const ROUND_BOSS_TEXTURE: CompressedTexture2D = preload("res://images/level_selection/round_boss.png")
const BOSS_SHADOW_COLOR: Color = Color("571c27")


var boss_type: GameData.BossTypes = GameData.BossTypes.NONE
var movement_delay: float = 0.0
var round_index: int = 0
var time_passed: float = 0.0


@onready var round_label: LabelShadowed = $CenterContainer / VBoxContainer / RoundLabel
@onready var round_value_label: LabelShadowed = $CenterContainer / VBoxContainer / RoundValueLabel
@onready var current_round_indicator: Sprite2D = $CurrentIndicatorSprite


static func create(parent: Node, round_index_value: int) -> LevelSelectionSquare:
	var scene: PackedScene = preload("res://scenes/level_selection/level_selection_square.tscn")
	var instance: LevelSelectionSquare = scene.instantiate()

	parent.add_child(instance)
	instance.round_index = round_index_value
	instance.round_value_label.text = str(round_index_value)
	instance.texture = ROUND_TEXTURE

	if round_index_value % 3 == 0:
		instance.boss_type = GameManager.get_boss_for_round(round_index_value)

		instance.texture = ROUND_BOSS_TEXTURE

		instance.round_label.shadow_color = BOSS_SHADOW_COLOR
		instance.round_label.outline_color = BOSS_SHADOW_COLOR
		instance.round_value_label.outline_color = BOSS_SHADOW_COLOR
		instance.round_value_label.shadow_color = BOSS_SHADOW_COLOR

	return instance


func _ready() -> void :
	movement_delay = get_index() * 0.4


func _process(delta: float) -> void :
	time_passed += delta * 5 * GameManager.timescale
	position.y = sin(time_passed + movement_delay) * 2.0
