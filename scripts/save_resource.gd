class_name SaveResource extends Resource

const SAVE_PATH := "user://save.tres"

@export var current_round: int = 1
@export var current_perks: Array[GameData.Perks] = []
@export var perk_levels: Dictionary[GameData.Perks, int] = {}
@export var original_pieces: Dictionary = {}
@export var rolls_left: int = 5
@export var boss_usage_history: Dictionary = {}
@export var deck_type: GameData.DeckTypes = GameData.DeckTypes.NORMAL
@export var speedrun_time: float = 0.0
@export var seed_string: String = ""
@export var cumulative_perks: Dictionary[GameData.Perks, int] = {}
@export var best_score: String = "0"
@export var blocks_rolled_count: int = 0
@export var blocks_skipped_count: int = 0

static func load_from_disk() -> SaveResource:
	if FileAccess.file_exists(SAVE_PATH):
		return ResourceLoader.load(SAVE_PATH) as SaveResource
	return null

static func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func write() -> void:
	ResourceSaver.save(self, SAVE_PATH)

static func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
