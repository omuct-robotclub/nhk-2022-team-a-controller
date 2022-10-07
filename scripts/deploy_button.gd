extends CheckButton

var cli_ := rosbridge.create_client("/deploy")

func _ready() -> void:
    connect("pressed", self, "_on_self_button_pressed")

func _on_self_button_pressed() -> void:
    var result = yield(cli_.call_service({ "deploy": pressed }), "completed")
    print(result)
