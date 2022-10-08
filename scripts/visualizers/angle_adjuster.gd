extends Node2D


var _button: CheckButton
var _robot
var _angle: float
var _touch_pos: Vector2


func _ready() -> void:
    _button = Globals.ui.find_node("AdjustAngleButton") as CheckButton
    _robot = get_parent().get_node("Robot")
    var err := _button.connect("pressed", self, "_on_button_pressed")
    assert(err != null)


func _on_button_pressed() -> void:
    update()


func _draw() -> void:
    if _button.pressed:
        draw_line(_robot.position, _robot.position + Vector2(15.0, 0.0).rotated(_angle), Color.aqua)


func _unhandled_input(event: InputEvent) -> void:
    if not _button.pressed: return
    if not (event is InputEventScreenDrag or event is InputEventScreenTouch): return

    if event is InputEventScreenTouch and event.pressed or event is InputEventScreenDrag:
        get_tree().set_input_as_handled()
        _touch_pos = get_global_transform().affine_inverse() * get_canvas_transform().affine_inverse() * event.position
        _angle = _touch_pos.angle_to_point(_robot.position)
        update()

    else:
        _robot.move_to(_robot.position, _angle)

