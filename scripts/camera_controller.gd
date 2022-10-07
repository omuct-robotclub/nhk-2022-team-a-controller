extends Camera2D


var _touches: Dictionary
var _prev_center: Vector2
var _prev_touches: Dictionary
var _prev_dist := 0.0



func _unhandled_input(event):
    if event is InputEventScreenTouch and event.is_pressed():
        _touches[event.index] = event

    elif event is InputEventScreenTouch and not event.is_pressed():
# warning-ignore:return_value_discarded
        _touches.erase(event.index)

    elif event is InputEventScreenDrag:
        _touches[event.index] = event

    if Input.is_action_pressed("zoom_in"):
        zoom *= Vector2(0.9, 0.9)

    if Input.is_action_just_pressed("zoom_out"):
        zoom *= Vector2(1.1, 1.1)

    if not _touches.empty():
        var center := Vector2(0.0, 0.0)
        var dist := 0.0

        for t in _touches.values():
            center += t.get_position() / len(_touches)

        for t in _touches.values():
            dist += abs((center - t.get_position()).length())

        if len(_touches) == len(_prev_touches):
            var d_pos := center - _prev_center
            var d_dist := dist - _prev_dist

            position -= d_pos * zoom
            zoom -= Vector2(d_dist, d_dist) * zoom / 500.0

        _prev_dist = dist
        _prev_center = center

    _prev_touches = _touches.duplicate(true)
