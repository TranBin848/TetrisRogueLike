extends CanvasLayer


var active: bool = false
var timepassed: float = 0.0
var paused: bool = true


@onready var timer_label: LabelShadowed = $MarginContainer/PanelContainer/TimerLabel


func _ready() -> void :
	timer_label.text = _format_time(timepassed)
	visible = active


func _process(delta: float) -> void :
	if paused:
		return

	timepassed += delta
	timer_label.text = _format_time(timepassed)



func _format_time(time: float) -> String:
	var minutes: int = int(time) / 60
	var seconds: int = int(time) % 60
	var milliseconds: int = int((time - int(time)) * 100)

	return "%02d:%02d:%02d" % [minutes, seconds, milliseconds]



func pause_timer() -> void :
	paused = true



func resume_timer() -> void :
	paused = false



func reset_timer() -> void :
	timepassed = 0.0
	timer_label.text = _format_time(timepassed)



func activate() -> void :
	active = true
	visible = true



func deactivate() -> void :
	active = false
	visible = false
