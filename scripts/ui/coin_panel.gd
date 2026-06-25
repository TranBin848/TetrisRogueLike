class_name CoinPanel extends HBoxContainer

@onready var coin_value_label: LabelShadowed = $CoinValue

func _ready() -> void :
	_update_coins(GameManager.coins)
	GameManager.coins_changed.connect(_update_coins)

func _update_coins(value: int) -> void :
	if not is_instance_valid(coin_value_label):
		return
	
	coin_value_label.text = str(value)
	
	# Simple pop animation
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	coin_value_label.scale = Vector2.ONE * 1.3
	tween.tween_property(coin_value_label, "scale", Vector2.ONE, 0.3 / GameManager.timescale)
