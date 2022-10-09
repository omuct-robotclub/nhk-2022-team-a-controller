tool
extends HBoxContainer

onready var _slider := $"%Slider"
onready var _label := $"%Label"

export var value := 0.0 setget set_value, get_value
export var min_value := 0.0 setget set_min_value
export var max_value := 0.0 setget set_max_value


func _ready() -> void:
    var err := _slider.connect("value_changed", self, "_update_label")
    assert(err == OK)
    _update_label(0.0)

func _update_label(new_value: float) -> void:
    _label.text = "%2.2f" % new_value

func set_value(new_value: float) -> void:
    if _slider != null:
        _slider.value = new_value
    value = new_value

func get_value() -> float:
    return value

func set_min_value(new_min_value: float) -> void:
    if _slider != null:
        _slider.min_value = new_min_value
    min_value = new_min_value

func set_max_value(new_max_value: float) -> void:
    if _slider != null:
        _slider.max_value = new_max_value
    max_value = new_max_value
