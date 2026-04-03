class_name PixelLineEdit extends LineEdit


func _get_font_variation() -> FontVariation:
    var is_alternative_font: bool = LabelShadowed.should_use_alternative_font_for_family(LabelShadowed.FontFamily.LARGE)

    if is_alternative_font:
        return LabelShadowed.LARGE_FONT_CJK_VARIATION
    else:
        return LabelShadowed.LARGE_FONT_VARIATION


func _get_font_size() -> int:
    var is_alternative_font: bool = LabelShadowed.should_use_alternative_font_for_family(LabelShadowed.FontFamily.LARGE)

    if is_alternative_font:
        return 11
    else:
        return 16


func _update_font() -> void :
    add_theme_font_override("font", _get_font_variation())
    add_theme_font_size_override("font_size", _get_font_size())


func _ready() -> void :
    _update_font()


func _notification(what: int) -> void :
    if what == NOTIFICATION_TRANSLATION_CHANGED:
        _update_font()
