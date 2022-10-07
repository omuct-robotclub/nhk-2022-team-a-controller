tool
extends HBoxContainer

signal submit(value)

export var texture: Texture setget set_texture
export var max_value := 3 setget set_max_value
export var value := 0 setget set_value
export(Gradient) var gradation: Gradient setget set_gradation
export var disable_color: Color setget set_disable_color
export var chamber_state := true setget set_chamber_state
export var separation := 40 setget set_separation


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

func set_chamber_state(v: bool):
    chamber_state = v
    _update_sprites()

func set_separation(v: int):
    separation = v
    _update_sprites()

func _new_texture_rect() -> TextureRect:
    var r := TextureRect.new()
    r.texture = texture
    r.size_flags_vertical = SIZE_EXPAND | SIZE_SHRINK_CENTER
    r.size_flags_horizontal = SIZE_EXPAND | SIZE_SHRINK_CENTER
    r.mouse_filter = MOUSE_FILTER_IGNORE
    return r

func _update_sprites():
    for c in get_children():
        if (c is TextureRect) or (c is VSeparator):
            c.queue_free()

    if gradation == null: return

    var in_chamber := _new_texture_rect()
    in_chamber.self_modulate = gradation.interpolate(1.0) if chamber_state else disable_color
    add_child(in_chamber)

    var sep := VSeparator.new()
    sep.mouse_filter = MOUSE_FILTER_IGNORE
    sep.add_constant_override("separation", separation)
    add_child(sep)

    for i in range(max_value):
        var r := _new_texture_rect()
        if i < value:
            r.modulate = gradation.interpolate(float(value - 1) / max(max_value - 1, 1))
        else:
            r.modulate = disable_color
        add_child(r)

func _gui_input(event: InputEvent):
    var sep := get_children()[1] as VSeparator
    var sep_center := sep.rect_position.x + sep.rect_size.x / 2
    var sep_right := sep.rect_position.x + sep.rect_size.x

    if event is InputEventScreenTouch and event.pressed and event.position.x < sep_center:
        chamber_state = !chamber_state
        _update_sprites()
        accept_event()

    elif (event is InputEventScreenTouch and event.pressed) or event is InputEventScreenDrag and event.position.x > sep_center:
        var idx := int(clamp(round((event.position.x - sep_right) / ((rect_size.x - sep_right) / max_value)), 0, max_value))
        set_value(idx)
        accept_event()

    elif event is InputEventScreenTouch and !event.pressed:
        emit_signal("submit", value)
        accept_event()
