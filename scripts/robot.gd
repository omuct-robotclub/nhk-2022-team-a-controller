extends Node
class_name Robot


signal distance_updated(distance)
signal pose_updated(position, rotation)
signal control_mode_changed(mode)


enum ControlMode {
    MANUAL = 0
    AUTO = 1
}

onready var _loader_state_sub = rosbridge.create_subscription(
    "launcher_interfaces/LoaderStateArray", "/loader_state", funcref(self, "_loader_state_cb"))

onready var _launch_client := rosbridge.create_client("/launch")
onready var _reload_client := rosbridge.create_client("/reload")
onready var _notify_reload_client := rosbridge.create_client("/notify_reloaded")
onready var _distance_sub := rosbridge.create_subscription("std_msgs/Float64", "/distance", funcref(self, "_distance_cb"))
var distance: float setget ,get_distance
onready var _robot_pose_sub := rosbridge.create_subscription("geometry_msgs/Pose2D", "/robot_pose", funcref(self, "_pose_callback"))
onready var _goal_pub := rosbridge.create_publisher("geometry_msgs/PoseStamped", "/goal_pose")
onready var _twist_pub = rosbridge.create_publisher("geometry_msgs/Twist", "/cmd_vel")
var _launchers: Array
var _loaders: Array
var position: Vector2 setget ,get_position
var rotation: float setget, get_rotation
var control_mode: int = ControlMode.MANUAL setget ,get_control_mode
var _param_event_handler := rosbridge.create_parameter_event_handler("/rud_controller_node", funcref(self, "_on_param_changed"))

class Launcher:
    var _robot: Robot
    var _idx: int

    func _init(robo: Robot, idx: int) -> void:
        _idx = idx
        _robot = robo

    func launch() -> void:
        var result = yield(_robot._launch_client.call_service({ "index": _idx }), "completed")
        print(result)


class Loader:
# warning-ignore:unused_signal
    signal state_changed()

    var _robot: Robot
    var _idx: int

    var _auto_reload: bool
    var _is_ready: bool
    var _ammo_left: int
    var _chamber_state: bool
    var _reload_progress: float

    var auto_reload: bool setget set_auto_reload
    var is_ready: bool setget ,get_is_ready
    var ammo_left: int setget set_ammo_left, get_ammo_left
    var chamber_state: bool setget set_chamber_state, get_chamber_state
    var reload_progress: float setget ,get_reload_progress

    func _init(robo: Robot, idx: int) -> void:
        _idx = idx
        _robot = robo

    func reload() -> void:
        _robot._reload_client.call_service({
            "loader_idx": _idx
        })

    func get_is_ready() -> bool: return _is_ready
    func get_ammo_left() -> int: return _ammo_left
    func get_chamber_state() -> bool: return _chamber_state
    func get_reload_progress() -> float: return _reload_progress

    func set_auto_reload(v: bool) -> void:
        rosbridge.set_parameter("nhka_hardware_node", "loader" + str(_idx) + ".auto_reload", v)
    func set_ammo_left(n: int) -> void:
        _robot._notify_reload_client.call_service({
            "loader_idx": _idx,
            "ammo_left": n,
            "chamber_state": -1
        })
    func set_chamber_state(s: bool) -> void:
        _robot._notify_reload_client.call_service({
            "loader_idx": _idx,
            "ammo_left": -1,
            "chamber_state": 1 if s else 0
        })


func _init() -> void:
    _launchers =  [Launcher.new(self, 0), Launcher.new(self, 1), Launcher.new(self, 2)]
    _loaders = [Loader.new(self, 0), Loader.new(self, 1), Loader.new(self, 2)]

func get_launcher(idx: int) -> Launcher:
    return _launchers[idx]

func get_loader(idx: int) -> Loader:
    return _loaders[idx]

func _loader_state_cb(msg: Dictionary) -> void:
    for loader_idx in 3:
        _loaders[loader_idx]._is_ready = msg["loader_states"][loader_idx]["is_ready"]
        _loaders[loader_idx]._ammo_left = msg["loader_states"][loader_idx]["ammo_left"]
        _loaders[loader_idx]._chamber_state = msg["loader_states"][loader_idx]["chamber_state"]
        _loaders[loader_idx]._reload_progress = msg["loader_states"][loader_idx]["reload_progress"]
        _loaders[loader_idx].emit_signal("state_changed")

func _distance_cb(msg: Dictionary) -> void:
    distance = msg["data"]
    emit_signal("distance_updated", distance)

func get_distance() -> float:
    return distance

func _pose_callback(msg: Dictionary) -> void:
    position.x = msg["x"]
    position.y = msg["y"]
    rotation = msg["theta"]
    emit_signal("pose_updated", position, rotation)

func get_position() -> Vector2:
    return position

func get_rotation() -> float:
    return rotation

func get_control_mode() -> int:
    return control_mode

func set_control_mode(mode: int) -> void:
    control_mode = mode
    var enable_control: bool
    match mode:
        ControlMode.AUTO:
            enable_control = true
        ControlMode.MANUAL:
            enable_control = false
        _:
            assert(false)

    yield(rosbridge.set_parameter("/rud_controller_node",
                                  "enable_control",
                                  enable_control),
          "completed")

func move_to(pos: Vector2, rot: float) -> void:
    print("moving to ", pos, " ", rot)
    set_control_mode(ControlMode.AUTO)
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

func set_velocity(linear: Vector2, angular: float) -> void:
    if control_mode == ControlMode.AUTO:
        set_control_mode(ControlMode.MANUAL)

    var msg = {
        "linear": {
            "x": linear.x,
            "y": linear.y,
            "z": 0.0,
        },
        "angular": {
            "x": 0.0,
            "y": 0.0,
            "z": angular,
        },
    }
    _twist_pub.publish(msg)

func _on_param_changed(name: String, value) -> void:
    match name:
        "enable_control":
            var prev := control_mode
            if value:
                control_mode = ControlMode.AUTO
            else:
                control_mode = ControlMode.MANUAL
            if prev != control_mode:
                emit_signal("control_mode_changed", control_mode)
