extends VBoxContainer

export var default_time := 150
var _start = false
var _elapsed := 0.0
onready var _label := $"%Label"
onready var _button := $"%Button"

func _ready() -> void:
    var err := _button.connect("pressed", self, "_on_button_pressed")
    assert(err == OK)

func _on_button_pressed() -> void:
    if _start:
        _elapsed = 0.0
        _start = false
        _button.text = "Start"
    else:
        _start = true
        _button.text = "Stop"

func _process(delta: float) -> void:
    if _start:
        _elapsed += delta
        _label.text = _to_min_sec(_elapsed)

func _to_min_sec(t: float) -> String:
    var sec := int(floor(fmod(t, 60.0)))
    var mins := int(floor(t / 60))
    return "%d : %02d" % [mins, sec]
