tool
extends HBoxContainer

signal submit(value)

export var texture: Texture setget set_texture
export var max_value := 3 setget set_max_value
export var value := 0 setget set_value
export(Gradient) var gradation: Gradient setget set_gradation
export var disable_color: Color setget set_disable_color


func _ready():
    _update_sprites()

func set_texture(v: Texture):
    texture = v
    _update_sprites()

func set_value(v: int):
    value = v
    _update_sprites()

func set_max_value(v: int):
    max_value = v
    _update_sprites()

func set_gradation(v: Gradient):
    gradation = v
    _update_sprites()

func set_disable_color(v: Color):
    disable_color = v
    _update_sprites()

func _update_sprites():
    for c in get_children():
        if c is TextureRect:
            c.queue_free()

    if gradation == null: return

    for i in range(max_value):
        var r = TextureRect.new()
        r.texture = texture
        r.size_flags_vertical = SIZE_EXPAND | SIZE_SHRINK_CENTER
        r.size_flags_horizontal = SIZE_EXPAND | SIZE_SHRINK_CENTER
        r.mouse_filter = MOUSE_FILTER_IGNORE
        if i < value:
            r.modulate = gradation.interpolate(float(value - 1) / max(max_value - 1, 1))
        else:
            r.modulate = disable_color
        add_child(r)

func _gui_input(event: InputEvent):
    if (event is InputEventScreenTouch and event.pressed) or event is InputEventScreenDrag:
        var idx = clamp(round(event.position.x / (rect_size.x / max_value)), 0, max_value)
        set_value(idx)
        accept_event()
    elif event is InputEventScreenTouch and !event.pressed:
        emit_signal("submit", value)
        accept_event()
