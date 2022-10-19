extends Node2D
class_name LaunchPositionSelector

signal launch_position_selected(pos, angle)

const _robot_rect := Rect2(-0.325, -0.375, 0.65, 0.75)
const _min_distance := 1.0

var _launcher: Dictionary
var _spot: Spot
var _distance_between_launcher_and_spot: float
var _landing_point: Vector2
var _launcher_offset: Vector2

var _launcher_pos: Vector2
var _robot_pos: Vector2
var _robot_angle: float

var _touch_angle_offset: float
var _has_touched := false
var _touch_pos: Vector2
var _touch_index := -1

func _init(launcher, spot) -> void:
    _launcher = launcher
    _spot = spot

    _landing_point = Vector2(_launcher["landing_point"]["x"], _launcher["landing_point"]["y"])
    _launcher_offset = Vector2(_launcher["pose"]["x"], _launcher["pose"]["y"])
    _distance_between_launcher_and_spot = (_landing_point + _launcher_offset).length()

func _unhandled_input(event) -> void:
    if event is InputEventScreenDrag or (event is InputEventScreenTouch and event.pressed):
        if not _has_touched:
            _touch_index = event.index
        else:
            if _touch_index != event.index:
                return

        get_tree().set_input_as_handled()

        _touch_pos = get_global_transform().affine_inverse() * get_canvas_transform().affine_inverse() * event.position
        var touch_angle = (_touch_pos - _spot.position).angle()
        if not _has_touched:
            _touch_angle_offset = 0.0
#            _touch_angle_offset = -touch_angle - PI / 2
        var launcher_angle = touch_angle + _touch_angle_offset
        if _spot.has_angle_limit:
            launcher_angle = clamp(launcher_angle, _spot.angle_min + _spot.rotation, _spot.angle_max + _spot.rotation)
        _launcher_pos = Vector2(1.0, 0.0).rotated(launcher_angle) * _distance_between_launcher_and_spot + _spot.position
        _robot_angle = PI + launcher_angle - _launcher["pose"]["theta"]
        _robot_pos = _launcher_pos - _launcher_offset.rotated(_robot_angle)

        _has_touched = true
        update()

    elif event is InputEventScreenTouch and not event.pressed:
        if not _has_touched: return
        if _touch_index != event.index: return

        get_tree().set_input_as_handled()

        if _touch_pos.distance_to(_spot.position) < _min_distance:
            print("canceled")
        else:
            _submit_pose(_robot_pos, _robot_angle)

        queue_free()

func _draw() -> void:
    var notin_cancel_area = _min_distance <= _touch_pos.distance_to(_spot.position)
    var color = Color.green if notin_cancel_area else Color.red
    var alt_color = Color.orange if notin_cancel_area else Color.red

    draw_arc(_spot.position, _distance_between_launcher_and_spot, 0.0, TAU, 100, color, 1, true)

    if _spot.has_angle_limit:
        draw_line(_spot.position, _spot.position + Vector2(1.0, 0.0).rotated(_spot.angle_min + _spot.rotation) * _distance_between_launcher_and_spot, alt_color)
        draw_line(_spot.position, _spot.position + Vector2(1.0, 0.0).rotated(_spot.angle_max + _spot.rotation) * _distance_between_launcher_and_spot, alt_color)

    if not _has_touched: return

    draw_line(_spot.position, _launcher_pos, color)

    draw_set_transform(_robot_pos, _robot_angle, Vector2(1.0, 1.0))
    draw_rect(_robot_rect, Color.aqua, false, 1.0, true)
    draw_line(Vector2.ZERO, Vector2(1.0, 0.0), Color.red)
    draw_line(Vector2.ZERO, Vector2(0.0, 1.0), Color.green)

func _submit_pose(pos: Vector2, angle: float) -> void:
    emit_signal("launch_position_selected", pos, angle)
