extends Node

export var twist_publish_rate := 30
onready var _last_twist_publish_time := OS.get_ticks_msec()

func _ready() -> void:
    pass

func _input(event: InputEvent) -> void:
#    var linear := Input.get_vector("backward", "forward", "right", "left")
#    var angular := Input.get_axis("turn_right", "turn_left")
#    var now := OS.get_ticks_msec()
#    if linear.length() < 0.01 or abs(angular) < 0.01 and (now - _last_twist_publish_time) > (1 / twist_publish_rate):
#        robot.set_velocity(linear, angular)
#        _last_twist_publish_time = now

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
