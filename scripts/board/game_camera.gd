class_name GameCamera extends Camera2D

static var _self: GameCamera = null

var original_offset: Vector2
var shake_tween: Tween

static func shake_randomly(value: float, duration: float) -> void :
	if _self:
		_self._shake_randomly(value, duration)

static func shake_direction(value: float, degrees: float, duration: float) -> void :
	if _self:
		_self._shake_direction(value, degrees, duration)


static func get_world_position() -> Vector2:
	if _self:
		return _self.global_position

	return Vector2.ZERO


func _ready() -> void :
	_self = self
	original_offset = offset


func _shake_randomly(intensity: float, duration: float) -> void :
	if shake_tween:
		shake_tween.kill()

	shake_tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	var shake_count = int(duration * 60)
	var shake_interval = duration / shake_count

	for i in shake_count:
		var random_offset = Vector2(
			randf_range( - intensity, intensity), 
			randf_range( - intensity, intensity)
		)
		shake_tween.tween_property(self, "offset", original_offset + random_offset, shake_interval)

	shake_tween.tween_property(self, "offset", original_offset, 0.1)

func _shake_direction(intensity: float, degrees: float, duration: float) -> void :
	if shake_tween:
		shake_tween.kill()

	var direction = Vector2.RIGHT.rotated(deg_to_rad(degrees))
	var shake_offset = direction * intensity

	shake_tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	shake_tween.tween_property(self, "offset", original_offset + shake_offset, 0.1)
	shake_tween.tween_property(self, "offset", original_offset, duration - 0.1)
