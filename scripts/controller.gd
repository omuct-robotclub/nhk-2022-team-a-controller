extends Node

export var linear_deadzone := 0.01
export var angular_deadzone := 0.01
export var twist_publish_rate := 30.0
onready var _last_twist_publish_time := OS.get_ticks_msec()

var _selected_launcher: int = -1

signal launcher_selected()

func _ready() -> void:
    pass

func _process(_delta: float) -> void:
    var now := OS.get_ticks_msec()
    if ((now - _last_twist_publish_time)/1000.0) < (1 / twist_publish_rate): return

    var linear := Vector2(Input.get_axis("backward", "forward"), Input.get_axis("right", "left"))
    var angular := Input.get_axis("turn_right", "turn_left")

    linear.x *= abs(linear.x)
    linear.y *= abs(linear.y)
    linear *= 2

    angular *= abs(angular)
    angular *= 2

    if robot.control_mode == Robot.ControlMode.MANUAL:
        robot.set_velocity(linear, angular)
        _last_twist_publish_time = now
    elif linear.length() > linear_deadzone or abs(angular) > angular_deadzone:
        robot.set_velocity(linear, angular)
        _last_twist_publish_time = now

func _feedback() -> void:
    for i in Input.get_connected_joypads():
        Input.start_joy_vibration(i, 1, 0, 0.1)
    Input.vibrate_handheld(50)

func _input(_event: InputEvent) -> void:
    if Input.is_action_just_pressed("step_turn_left"):
        robot.move_to(robot.position, robot.rotation + deg2rad(0.5))
    if Input.is_action_just_pressed("step_turn_right"):
        robot.move_to(robot.position, robot.rotation - deg2rad(0.5))

    if Input.is_action_just_pressed("fire_0"):
        _selected_launcher = 0
        emit_signal("launcher_selected")
        _feedback()
    elif Input.is_action_just_pressed("fire_1"):
        _selected_launcher = 1
        emit_signal("launcher_selected")
        _feedback()
    elif Input.is_action_just_pressed("fire_2"):
        _selected_launcher = 2
        emit_signal("launcher_selected")
        _feedback()

    if Input.is_action_just_pressed("reload_mod"):
        if _selected_launcher != -1:
            robot.get_loader(_selected_launcher).reload()
            _feedback()

    if Input.is_action_just_pressed("fire"):
        if _selected_launcher != -1:
            robot.get_launcher(_selected_launcher).launch()
            _feedback()


func get_selected_launcher() -> int:
    return _selected_launcher

