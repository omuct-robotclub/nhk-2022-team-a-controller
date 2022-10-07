extends Node2D


const wp_scene := preload("res://scenes/waypoint.tscn")
var _wp_sub: RosBridge.Subscription
var _goal_pub: RosBridge.Publisher
var _prev_waypoints: Array
var _wp_nodes: Array
var _param_cli: RosBridge.Client

func _ready() -> void:
    var err := rosbridge.connect("connection_established", self, "_on_connection_established")
    assert(err == OK)

func _on_connection_established() -> void:
    _wp_sub = rosbridge.create_subscription("geometry_msgs/PoseArray", "/waypoints", funcref(self, "_wp_callback"))
    _goal_pub = rosbridge.create_publisher("geometry_msgs/PoseStamped", "/goal_pose")
    _param_cli = rosbridge.create_client("/rud_controller_node/set_parameters")

func pose_msg_to_transform2d(msg: Dictionary) -> Transform2D:
    var q := Quat(
        msg["orientation"]["x"],
        msg["orientation"]["y"],
        msg["orientation"]["z"],
        msg["orientation"]["w"])

    return Transform2D(q.get_euler().z, Vector2(msg["position"]["x"], msg["position"]["y"]))


func _wp_callback(msg: Dictionary) -> void:
    var waypoints := []
    for p in msg["poses"]:
        waypoints.push_back(pose_msg_to_transform2d(p))

    if _prev_waypoints != waypoints:
        for n in _wp_nodes:
            (n as Node).queue_free()
        _wp_nodes.clear()

        for p in waypoints:
            var wp := wp_scene.instance()
            wp.transform = p
            _wp_nodes.push_back(wp)
            var err := wp.connect("clicked", self, "_on_wp_clicked")
            assert(err == OK)
            add_child(wp)

        _prev_waypoints = waypoints.duplicate()

func _on_wp_clicked(wp: WaypointNode) -> void:
    for w in _wp_nodes:
        if w == wp:
            wp.activate()
            yield(rosbridge.set_parameter("/rud_controller_node",
                                          "enable_control",
                                          true),
                  "completed")
            var ori = Quat(Vector3(0, 0, 1), wp.rotation)
            var msg = {
                "header": { "frame_id": "map" },
                "pose": {
                    "position": {
                        "x": wp.position.x,
                        "y": wp.position.y,
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
        else:
            w.deactivate()
