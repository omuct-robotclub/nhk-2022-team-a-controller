extends Sprite
class_name Spot

var spot_type: int
var has_angle_limit: bool
var angle_min: float
var angle_max: float

signal input_event()

func _ready() -> void:
    var err := $Area2D.connect("input_event", self, "_on_area_input_event")
    assert(err == OK)

func _on_area_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
    emit_signal("input_event", event)
