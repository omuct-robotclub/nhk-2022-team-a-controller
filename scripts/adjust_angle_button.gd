extends CheckButton


func _ready() -> void:
    var err := connect("pressed", self, "_on_button_pressed")
    assert(err == OK)


func _on_button_pressed() -> void:
    print(pressed)
