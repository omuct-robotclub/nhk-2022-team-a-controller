extends HBoxContainer


export var selected_alpha := 1.0
export var unselected_alpha := 0.5

export var ready_color := Color.greenyellow
export var reloading_color := Color.yellow

onready var _left := $"%Left"
onready var _right := $"%Right"


func _ready() -> void:
    var res := controller.connect("launcher_selected", self, "_on_launcher_selected")
    res = res || robot.get_loader(0).connect("state_changed", self, "_on_loader_state_changed", [0])
    res = res || robot.get_loader(2).connect("state_changed", self, "_on_loader_state_changed", [2])
    assert(res == OK)
    _update_alpha()

func _on_loader_state_changed(idx: int) -> void:
    var l = robot.get_loader(idx)
    var cr: ColorRect
    if idx == 0:
        cr = _left
    elif idx == 2:
        cr = _right
    else:
        return

    if l.get_is_ready():
        cr.color.r = ready_color.r
        cr.color.g = ready_color.g
        cr.color.b = ready_color.b
    else:
        cr.color.r = reloading_color.r
        cr.color.g = reloading_color.g
        cr.color.b = reloading_color.b


func _on_launcher_selected() -> void:
    _update_alpha()

func _update_alpha() -> void:
    var sel := controller.get_selected_launcher()
    match sel:
        -1:
            _left.color.a = unselected_alpha
            _right.color.a = unselected_alpha
        0:
            _left.color.a = selected_alpha
            _right.color.a = unselected_alpha
        2:
            _left.color.a = unselected_alpha
            _right.color.a = selected_alpha

