extends Control


export var linear_scale := 1.0
export var angular_scale := 1.0


func _ready():
    var err := Input.connect("joy_connection_changed", self, "_on_joy_connection_changed")

    err = err || $"%LeftJoystick".connect("pressed", self, "_on_joystick_pressed")
    err = err || $"%RightJoystick".connect("pressed", self, "_on_joystick_pressed")

    assert(err == OK)

    if Input.get_connected_joypads().size() != 0:
        $"%LeftJoystick".hide()
        $"%RightJoystick".hide()

func _on_joystick_pressed():
    robot.control_mode = Robot.ControlMode.MANUAL

func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
    if connected:
        print("Joystick connected: ", Input.get_joy_name(device_id))
        $"%LeftJoystick".hide()
        $"%RightJoystick".hide()
    else:
        print("Joystick disconnected: ", Input.get_joy_name(device_id))
        $"%LeftJoystick".show()
        $"%RightJoystick".show()
