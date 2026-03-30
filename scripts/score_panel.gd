extends PanelContainer

@onready var target_score_label: LabelShadowed= $VBoxContainer/TargetScore/VBoxContainer/TargetValue
@onready var score_label: LabelShadowed = $VBoxContainer/Score/VBoxContainer/ScoreValue
@onready var point_value_label: RichTextLabelShadowed = $VBoxContainer/HBoxContainer/Points/VBoxContainer/PointValue
@onready var mul_value_label: RichTextLabelShadowed = $VBoxContainer/HBoxContainer/Multiplier/VBoxContainer/MulValue

 
func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	#GameManager.points_changed.connect(_on_points_changed)
	GameManager.multiplier_changed.connect(_on_multiplier_changed)
	_refresh_all()
 
 
func _refresh_all() -> void:
	#target_score_label.text = _format_number(GameManager.target_score)
	score_label.text = _format_number(GameManager.score)
	#point_value_label.text = _format_number(GameManager.points)
	mul_value_label.text = _format_number(GameManager.multiplier)
 
 
func _on_score_changed(value: int) -> void:
	score_label.text = _format_number(value)
 
 
func _on_points_changed(value: int) -> void:
	point_value_label.text = _format_number(value)
 
 
func _on_multiplier_changed(value: int) -> void:
	mul_value_label.text = _format_number(value)
 
 
 
func _format_number(value: int) -> String:
	var s := str(value)
	var result := ""
	var count := 0
 
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
 
	return result
 
