extends HBoxContainer


export var manual_control_color := Color.orange
export var auto_control_color := Color.green


func _ready() -> void:
    var err := robot.connect("control_mode_changed", self, "_on_control_mode_changed")
    assert(err == OK)

func _on_control_mode_changed(mode: int) -> void:
    match mode:
        Robot.ControlMode.MANUAL:
            $Indicator.self_modulate = manual_control_color
            $Indicator.text = "Manual"
        Robot.ControlMode.AUTO:
            $Indicator.self_modulate = auto_control_color
            $Indicator.text = "Auto"
