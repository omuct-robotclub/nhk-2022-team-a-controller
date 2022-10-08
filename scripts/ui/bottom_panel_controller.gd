extends Control


onready var _open_button := $"%OpenButton"
onready var _close_button := $"%CloseButton"
onready var _open_anim := $"%OpenAnim"
onready var _tabs := $"%Tabs"
onready var _tab_container := $"%ScrollTabContainer"


var _is_opened = false


func _ready():
    var err := _open_button.connect("pressed", self, "_open")
    err = err | _close_button.connect("pressed", self, "_close")

    for i in _tabs.get_child_count():
        _tabs.get_child(i).connect("pressed", self, "_on_tab_pressed", [i])

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
