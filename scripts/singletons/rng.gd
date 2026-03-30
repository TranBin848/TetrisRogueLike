extends Node

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _current_seed_hashed: int = 0
var _current_seed_string: String = ""


func _ready() -> void :
	set_random_seed()


func randf() -> float:
	return _rng.randf()


func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)


func randi() -> int:
	return _rng.randi()


func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


func pick_random(array: Array) -> Variant:
	if array.is_empty():
		return null
	return array[_rng.randi() % array.size()]


func shuffle(array: Array) -> void :
	var n: int = array.size()
	for i in range(n - 1, 0, -1):
		var j: int = _rng.randi() % (i + 1)
		var temp: Variant = array[i]
		array[i] = array[j]
		array[j] = temp


func set_custom_seed(seed_string: String) -> void :
	var trimmed_seed: String = seed_string.substr(0, 10)

	_current_seed_string = trimmed_seed
	_current_seed_hashed = trimmed_seed.hash()

	_rng.seed = _current_seed_hashed

	print("🎲 [Random] Set custom seed: %s (hashed: %d)" % [_current_seed_string, _current_seed_hashed])


func set_random_seed() -> void :
	var current_time: String = str(Time.get_unix_time_from_system())
	var trimmed_seed: String = str(current_time).substr(0, 10)

	_current_seed_hashed = trimmed_seed.hash()
	_current_seed_string = trimmed_seed

	_rng.seed = _current_seed_hashed

	print("🎲 [Random] Randomized seed: %s (hashed: %d)" % [_current_seed_string, _current_seed_hashed])


func get_current_seed_string() -> String:
	return _current_seed_string
