@tool
class_name CountPanelContainer extends PanelContainer

@export var margin: int = 0
@export var text: String = "0":
    set(value):
        text = value

        if is_instance_valid(count_label):
            count_label.text = text


@onready var count_label: LabelShadowed = $CountLabel


func _ready() -> void :
    count_label.text = text
    count_label.position = Vector2.ZERO - Vector2(margin, margin)

    count_label.resized.connect( func() -> void :
        await get_tree().process_frame

        size = get_combined_minimum_size()
        position = Vector2.ZERO - Vector2(margin, margin)
    )
