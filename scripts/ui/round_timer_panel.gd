extends PanelContainer

@onready var time_value: LabelShadowed = $VBoxContainer/TimeContainer/VBoxContainer/TimeValue

var _pulse_timer: float = 0.0

func _process(delta: float) -> void:
	if not is_instance_valid(time_value):
		return
		
	var time_left: float = GameManager.round_time_left
	var minutes: int = int(time_left) / 60
	var seconds: int = int(time_left) % 60
	
	time_value.text = "%02d:%02d" % [minutes, seconds]
	
	if time_left <= 10.0 and GameManager.is_timer_active:
		time_value.font_color = Color.RED
		_pulse_timer += delta * 5.0
		var scale_val = 1.0 + sin(_pulse_timer) * 0.1
		time_value.scale = Vector2(scale_val, scale_val)
		time_value.pivot_offset = time_value.size / 2
	else:
		time_value.font_color = Color.WHITE
		time_value.scale = Vector2.ONE
