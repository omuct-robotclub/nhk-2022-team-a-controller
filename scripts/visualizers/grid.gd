tool
extends Node2D


export var line_pitch := 1.0 setget set_line_pitch
export var line_count := 11 setget set_line_count
export var line_color := Color(1.0, 1.0, 1.0, 0.2) setget set_line_color

func set_line_pitch(v: float):
    line_pitch = v
    update()

func set_line_count(v: int):
    line_count = v
    update()

func set_line_color(v: Color):
    line_color = v
    update()

func _draw():
    var width = line_pitch * (line_count + 1)
    for i in line_count:
        var x = -width / 2
        var y = width / 2 - line_pitch * (i + 1)
        draw_line(Vector2(x, y), Vector2(x + width, y), line_color)

        draw_line(Vector2(y, x), Vector2(y, x + width), line_color)
#		draw_line(Vector2(y, x), Vector2(y + width, x), line_color)
