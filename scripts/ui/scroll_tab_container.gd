tool
extends Container
class_name ScrollTabContainer

export var current_tab := 0 setget set_current_tab
export var transition_speed := 0.1
export var separation := 1.0

var _current_tab := float(current_tab)
var _tween: SceneTreeTween

func _ready() -> void:
    pass

func next_tab() -> void:
    set_current_tab(current_tab + 1)

func prev_tab() -> void:
    set_current_tab(current_tab - 1)

func get_control_children() -> Array:
    var children := []
    for c in get_children():
        if c is Control:
            children.push_back(c)
    return children

func sort_children(t := float(current_tab)) -> void:
    var children := get_control_children()
    _current_tab = t

    for i in children.size():
        var offset = (get_rect().size.x + separation) * (i - t)
        var c := children[i] as Control
        c.rect_rotation = 0
        c.rect_position.x = offset
        c.rect_position.y = 0
        c.rect_size = rect_size
        c.rect_scale = Vector2.ONE

func set_current_tab(i: int) -> void:
    current_tab = clamp(i, 0, get_control_children().size() - 1)

    var transition_time := transition_speed * abs(current_tab - _current_tab)

    if _tween != null:
        _tween.kill()
        _tween = null

    _tween = get_tree().create_tween()
    _tween.tween_method(self, "sort_children", _current_tab, float(current_tab), transition_time) \
        .set_ease(Tween.EASE_OUT) \
        .set_trans(Tween.TRANS_CUBIC)

func _notification(what: int) -> void:
    match what:
        NOTIFICATION_SORT_CHILDREN:
            sort_children()
