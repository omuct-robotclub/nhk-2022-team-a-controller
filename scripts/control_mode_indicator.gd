extends HBoxContainer


export var manual_control_color := Color.orange
export var auto_control_color := Color.green


var _param_event_handler := rosbridge.create_parameter_event_handler("/rud_controller_node", funcref(self, "_on_param_changed"))


func _ready() -> void:
    pass

func _set_manual_control(manual_control: bool) -> void:
    if manual_control:
        $Indicator.self_modulate = manual_control_color
        $Indicator.text = "Manual"
    else:
        $Indicator.self_modulate = auto_control_color
        $Indicator.text = "Auto"

func _on_param_changed(name: String, value) -> void:
    if name == "enable_control":
        _set_manual_control(not value)
