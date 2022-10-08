extends Node

export var linear_deadzone := 0.01
export var angular_deadzone := 0.01
export var twist_publish_rate := 30.0
onready var _last_twist_publish_time := OS.get_ticks_msec()

func _ready() -> void:
    pass

func _process(_delta: float) -> void:
    var now := OS.get_ticks_msec()
    if (now - _last_twist_publish_time) < (1 / twist_publish_rate): return

    var linear := Input.get_vector("backward", "forward", "right", "left")
    var angular := Input.get_axis("turn_right", "turn_left")
    if linear.length() < linear_deadzone or abs(angular) < angular_deadzone:
        robot.set_velocity(linear, angular)
        _last_twist_publish_time = now

func _input(_event: InputEvent) -> void:
    if Input.is_action_just_pressed("step_turn_left"):
        robot.move_to(robot.position, robot.rotation - deg2rad(0.5))
    if Input.is_action_just_pressed("step_turn_right"):
        robot.move_to(robot.position, robot.rotation + deg2rad(0.5))

    if Input.is_action_pressed("reload_mod"):
        if Input.is_action_just_pressed("fire_0"):
            robot.get_loader(0).reload()
        elif Input.is_action_just_pressed("fire_1"):
            robot.get_loader(1).reload()
        elif Input.is_action_just_pressed("fire_2"):
            robot.get_loader(2).reload()
    else:
        if Input.is_action_just_pressed("fire_0"):
            robot.get_launcher(0).launch()
        elif Input.is_action_just_pressed("fire_1"):
            robot.get_launcher(1).launch()
        elif Input.is_action_just_pressed("fire_2"):
            robot.get_launcher(2).launch()
