extends Area2D
class_name WaypointNode


signal clicked(wp)


export var inactive_color: Color = Color(0.0, 1.0, 1.0)
export var active_color: Color = Color(0.0, 0.5, 1.0)


var color = inactive_color setget set_color
var click_pos: Vector2


func _draw():
    pass
#    draw_circle(Vector2(), 0.1, color)
#	draw_rect(Rect2(Vector2(-0.2, -0.1), Vector2(0.1, 0.2)), ColorN("green"), false, 0.01, true)
#    draw_line(Vector2(), Vector2(1.0, 0.0), color, 0.01, true)
#    draw_arc(Vector2(), 0.5, -PI/4, PI/4, 36, color, 0.01, true)

func _ready():
    pass

func set_color(c: Color):
    $Sprite.modulate = c
    update()

func activate():
    set_color(active_color)

func deactivate():
    set_color(inactive_color)

func _on_Waypoint_input_event(_waypoint, event, _shape_idx):
    if event is InputEventScreenTouch:
        if event.pressed:
            click_pos = event.position
        else:
            if (click_pos - event.position).length() < 10:
                emit_signal("clicked", self)

