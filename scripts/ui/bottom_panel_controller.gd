extends Control


onready var _open_button := $"%OpenButton"
onready var _close_button := $"%CloseButton"
onready var _open_anim := $"%OpenAnim"
onready var _tabs := $"%Tabs"
onready var _tab_container := $"%ScrollTabContainer"


var _is_opened = false


func _ready():
    var err := _open_button.connect("pressed", self, "_open")
    err = err || _close_button.connect("pressed", self, "_close")

    for i in _tabs.get_child_count():
        err = err || _tabs.get_child(i).connect("pressed", self, "_on_tab_pressed", [i])

    var window_size := OS.get_real_window_size()
    var safe_area := OS.get_window_safe_area()
    var viewport_rect := get_viewport_rect()

    var x_scale := viewport_rect.size.x / window_size.x
    var y_scale := viewport_rect.size.y / window_size.y

    var margin_container := $"%MarginContainer"

    margin_container.margin_left = safe_area.position.x * x_scale
    margin_container.margin_right = (window_size.x - (safe_area.position.x + safe_area.size.x)) * x_scale
    margin_container.margin_top = safe_area.position.y * y_scale
    margin_container.margin_bottom = (window_size.y - (safe_area.position.y + safe_area.size.y)) * y_scale

    assert(err == OK)

func _open():
    _open_anim.play("OpenAnim")
    _is_opened = true

func _close():
    _open_anim.play_backwards("OpenAnim")
    _is_opened = false

func _toggle():
    if _is_opened:
        _open()
    else:
        _close()

func _on_tab_pressed(idx: int) -> void:
    for btn in _tabs.get_children():
        btn.flat = false
    _tabs.get_child(idx).flat = true
    _tab_container.current_tab = idx
