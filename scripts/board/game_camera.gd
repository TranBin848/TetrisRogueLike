class_name GameCamera extends Camera2D

# =============================================================================
# STATE
# =============================================================================

var original_offset: Vector2
var shake_tween: Tween

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	original_offset = offset

# =============================================================================
# SHAKE EFFECTS
# =============================================================================

## Shake camera randomly in all directions
func shake_randomly(intensity: float, duration: float) -> void:
	if shake_tween:
		shake_tween.kill()

	shake_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var shake_count: int = int(duration * 30)
	var shake_interval: float = duration / shake_count

	for i in shake_count:
		var random_offset: Vector2 = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		shake_tween.tween_property(self, "offset", original_offset + random_offset, shake_interval)

	shake_tween.tween_property(self, "offset", original_offset, 0.1)


## Shake camera in a specific direction
func shake_direction(intensity: float, degrees: float, duration: float) -> void:
	if shake_tween:
		shake_tween.kill()

	var direction: Vector2 = Vector2.RIGHT.rotated(deg_to_rad(degrees))
	var shake_offset: Vector2 = direction * intensity

	shake_tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	shake_tween.tween_property(self, "offset", original_offset + shake_offset, 0.1)
	shake_tween.tween_property(self, "offset", original_offset, duration - 0.1)


## Quick punch effect (for hard drops, etc)
func punch(direction: Vector2, intensity: float) -> void:
	if shake_tween:
		shake_tween.kill()

	var punch_offset: Vector2 = direction.normalized() * intensity

	shake_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	shake_tween.tween_property(self, "offset", original_offset + punch_offset, 0.05)
	shake_tween.tween_property(self, "offset", original_offset, 0.3)