extends Control


onready var _expand_button := $"%ExpandButton"
onready var _expand_anim := $"%ExpandAnim"


var _is_expanded = false


func _ready():
    var err := _expand_button.connect("pressed", self, "_on_expand_button_pressed")
    assert(err == OK)

func _expand():
    _expand_anim.play("ExpandAnim")
    _is_expanded = true

func _shrink():
    _expand_anim.play_backwards("ExpandAnim")
    _is_expanded = false

func _toggle_expand():
    if _is_expanded:
        _shrink()
    else:
        _expand()

func _on_expand_button_pressed():
    _toggle_expand()
