extends Control


export var max_twist_publish_rate := 30.0 setget set_max_twist_publish_rate
export var min_twist_publish_rate := 4.0
export var linear_scale := 1.0
export var angular_scale := 1.0

var _twist_pub: RosBridge.Publisher
var _timer: Timer
var _param_cli: RosBridge.Client
var _last_twist_publish: float

var _prev_linear: Vector3
var _prev_angular: Vector3

var _param_event_handler := rosbridge.create_parameter_event_handler("/rud_controller_node", funcref(self, "_on_param_changed"))
var _manual_control := false

# aaa

func _ready():
    var err := rosbridge.connect("connection_established", self, "_on_connection_established")
    err = err || rosbridge.connect("disconnected", self, "_on_disconnected")
    err = err || Input.connect("joy_connection_changed", self, "_on_joy_connection_changed")

    _timer = Timer.new()
    err = err || _timer.connect("timeout", self, "_publish_twist")
    _timer.one_shot = false
    set_max_twist_publish_rate(max_twist_publish_rate)
    add_child(_timer)
    _timer.start()

    err = err || $"%LeftJoystick".connect("pressed", self, "_on_joystick_pressed")
    err = err || $"%RightJoystick".connect("pressed", self, "_on_joystick_pressed")

    assert(err == OK)

    if Input.get_connected_joypads().size() != 0:
        $"%LeftJoystick".hide()
        $"%RightJoystick".hide()

func _get_linear_input() -> Vector3:
    return Vector3(
        Input.get_action_strength("forward") - Input.get_action_strength("backward"),
        Input.get_action_strength("left") - Input.get_action_strength("right"),
        0.0)

func _get_angular_input() -> Vector3:
    return Vector3(
        0.0,
        0.0,
        Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right"))

func _publish_twist():
    if _twist_pub == null: return

    var linear := _get_linear_input() * linear_scale
    var angular := _get_angular_input() * angular_scale

    var now = Time.get_ticks_msec() / 1000.0
    if linear != _prev_linear or angular != _prev_angular or ((now - _last_twist_publish) >= 1.0 / min_twist_publish_rate and _manual_control):
        if _twist_pub != null and _param_cli != null:
            _prev_linear = linear
            _prev_angular = angular
            var msg = {
                "linear": {
                    "x": linear.x,
                    "y": linear.y,
                    "z": linear.z,
                },
                "angular": {
                    "x": angular.x,
                    "y": angular.y,
                    "z": angular.z,
                },
            }
            _twist_pub.publish(msg)
            _last_twist_publish = now
            if not _manual_control:
                rosbridge.set_parameter("/rud_controller_node", "enable_control", false)
                _manual_control = true
                print("manual control: ", _manual_control)

func _on_joystick_pressed():
    if not _manual_control:
        rosbridge.set_parameter("/rud_controller_node", "enable_control", false)
        _manual_control = true
        print("manual control: ", _manual_control)

func set_max_twist_publish_rate(rate: float):
    _timer.wait_time = 1.0 / rate
    max_twist_publish_rate = rate

func _on_connection_established():
    _twist_pub = rosbridge.create_publisher("geometry_msgs/Twist", "/cmd_vel")
    _param_cli = rosbridge.create_client("/rud_controller_node/set_parameters")
    $"%ConnectionState".text = "Connected"
    $"%ConnectionState".self_modulate = Color(0.0, 1.0, 0.0)

func _on_disconnected():
    $"%ConnectionState".text = "Disconnected"
    $"%ConnectionState".self_modulate = Color(1.0, 0.0, 0.0)

func _on_param_changed(name: String, value):
    if name == "enable_control":
        _manual_control = not value
        print("manual control: ", _manual_control)

func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
    if connected:
        print("Joystick connected: ", Input.get_joy_name(device_id))
        $LeftJoystick.hide()
        $RightJoystick.hide()
    else:
        print("Joystick disconnected: ", Input.get_joy_name(device_id))
        $LeftJoystick.show()
        $RightJoystick.show()
