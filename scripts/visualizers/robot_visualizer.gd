extends Node2D
class_name RobotVisualizer

export var timeout_color := Color(0.3, 0.3, 0.3)
export var timeout := 1.0

var _timer: Timer
onready var _robot_pose_sub := rosbridge.create_subscription("geometry_msgs/Pose2D", "/robot_pose", funcref(self, "_pose_callback"))
onready var _goal_pub := rosbridge.create_publisher("geometry_msgs/PoseStamped", "/goal_pose")


func _ready() -> void:
    _timer = Timer.new()
    _timer.wait_time = timeout
    _timer.one_shot = true
    add_child(_timer)

    var err := _timer.connect("timeout", self, "_on_timer_timeout")
    assert(err == OK)

    $Sprite.self_modulate = timeout_color
    update()

func _pose_callback(msg: Dictionary) -> void:
    position.x = msg.x
    position.y = msg.y
    rotation = msg.theta

    $Sprite.self_modulate = Color(1.0, 1.0, 1.0)
    _timer.start()

func _on_timer_timeout() -> void:
    $Sprite.self_modulate = timeout_color

func _process(delta: float) -> void:
    update()

func _draw() -> void:
    # draw_line(Vector2.ZERO, Vector2(10000.0, 0.0), Color.pink)
    draw_line(Vector2.ZERO, Vector2(robot.distance, 0.0), Color.red)
    draw_line(Vector2(robot.distance, -0.5), Vector2(robot.distance, 0.5), Color.red)

func move_to(pos: Vector2, rot: float) -> void:
    print("moving to ", pos, " ", rot)
    yield(rosbridge.set_parameter("/rud_controller_node",
                                  "enable_control",
                                  true),
          "completed")
    var ori = Quat(Vector3(0, 0, 1), rot)
    var msg = {
        "header": { "frame_id": "map" },
        "pose": {
            "position": {
                "x": pos.x,
                "y": pos.y,
                "z": 0.0
            },
            "orientation": {
                "w": ori.w,
                "x": ori.x,
                "y": ori.y,
                "z": ori.z
            }
        }
    }

    _goal_pub.publish(msg)
    print("goal pose published")
