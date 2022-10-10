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
onready var _enable_control := rosbridge.create_parameter_wrapper("/rud_controller_node", "enable_control", false)
var _launchers: Array
var _loaders: Array
var position: Vector2 setget ,get_position
var rotation: float setget, get_rotation
var control_mode: int = ControlMode.MANUAL setget ,get_control_mode
#var _rud_param_event_handler := rosbridge.create_parameter_event_handler("/rud_controller_node", funcref(self, "_on_rud_param_changed"))
var _param_event_handler := rosbridge.create_parameter_event_handler("/nhka_hardware_node", funcref(self, "_on_param_changed"))
var _drive_wheels: Array
var _pids: Dictionary
var _rud: RudController

class Launcher extends Reference:
    var _robot: Robot
    var _idx: int

    func _init(robo: Robot, idx: int) -> void:
        _idx = idx
        _robot = robo

    func launch() -> void:
        var result = yield(_robot._launch_client.call_service({ "index": _idx }), "completed")
        print(result)


class Loader extends Reference:
# warning-ignore:unused_signal
    signal state_changed()

    var _robot: Robot
    var _idx: int

    var _auto_reload: RosBridge.Parameter
    var _is_ready: bool
    var _ammo_left: int
    var _chamber_state: bool
    var _reload_progress: float

    var auto_reload: bool setget set_auto_reload, get_auto_reload
    var is_ready: bool setget ,get_is_ready
    var ammo_left: int setget set_ammo_left, get_ammo_left
    var chamber_state: bool setget set_chamber_state, get_chamber_state
    var reload_progress: float setget ,get_reload_progress

    func _init(robo: Robot, idx: int) -> void:
        _idx = idx
        _robot = robo
        _auto_reload = rosbridge.create_parameter_wrapper("/nhka_hardware_node", "loader" + str(_idx) + ".auto_reload", false)

    func reload() -> void:
        _robot._reload_client.call_service({
            "loader_idx": _idx
        })

    func get_auto_reload() -> bool: return _auto_reload.get_value()
    func get_is_ready() -> bool: return _is_ready
    func get_ammo_left() -> int: return _ammo_left
    func get_chamber_state() -> bool: return _chamber_state
    func get_reload_progress() -> float: return _reload_progress

    func set_auto_reload(v: bool) -> void: _auto_reload.set_value(v)
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


class PidController extends Reference:
    var _robo: Robot
    var _name: String

    var kp: RosBridge.Parameter setget ,get_kp
    var ki: RosBridge.Parameter setget ,get_ki
    var kd: RosBridge.Parameter setget ,get_kd

    func _init(robo: Robot, node: String, param_base: String) -> void:
        _robo = robo
        _name = param_base
        kp = rosbridge.create_parameter_wrapper(node, _name + ".p", 0.0)
        ki = rosbridge.create_parameter_wrapper(node, _name + ".i", 0.0)
        kd = rosbridge.create_parameter_wrapper(node, _name + ".d", 0.0)

    func get_kp() -> RosBridge.Parameter: return kp
    func get_ki() -> RosBridge.Parameter: return ki
    func get_kd() -> RosBridge.Parameter: return kd


class DriveWheel extends Reference:
    var _robo: Robot
    var pid: PidController setget ,get_pid

    func _init(robo: Robot, wheel_name: String) -> void:
        _robo = robo
        pid = PidController.new(robo, "/nhka_hardware_node", wheel_name)

    func get_pid() -> PidController: return pid


class RudController extends Reference:
    var pid_x: PidController
    var pid_y: PidController
    var pid_yaw: PidController

    func _init(robo: Robot) -> void:
        pid_x = PidController.new(robot, "/rud_controller_node", "pid_x")
        pid_y = PidController.new(robot, "/rud_controller_node", "pid_y")
        pid_yaw = PidController.new(robot, "/rud_controller_node", "pid_angular")


func _init() -> void:
    _launchers =  [Launcher.new(self, 0), Launcher.new(self, 1), Launcher.new(self, 2)]
    _loaders = [Loader.new(self, 0), Loader.new(self, 1), Loader.new(self, 2)]
    _drive_wheels = [DriveWheel.new(self, "dw0"), DriveWheel.new(self, "dw1"), DriveWheel.new(self, "dw2")]
    _rud = RudController.new(self)
    _pids = {"dw0":_drive_wheels[0].pid, "dw1":_drive_wheels[1].pid, "dw2":_drive_wheels[2].pid, "x": _rud.pid_x, "y": _rud.pid_y, "yaw": _rud.pid_yaw,}

func _ready() -> void:
    var err := _enable_control.connect("value_updated", self, "_on_enable_control_updated")
    assert(err == OK)

func _on_enable_control_updated(new_value: bool) -> void:
    control_mode = ControlMode.AUTO if new_value else ControlMode.MANUAL
    emit_signal("control_mode_changed", control_mode)

func get_launcher(idx: int) -> Launcher:
    return _launchers[idx]

func get_loader(idx: int) -> Loader:
    return _loaders[idx]

func get_drive_wheel(idx: int) -> DriveWheel:
    return _drive_wheels[idx]

func get_pid(n: String) -> PidController:
    return _pids[n]

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
    print(mode)
    var enable_control: bool
    match mode:
        ControlMode.AUTO:
            enable_control = true
        ControlMode.MANUAL:
            enable_control = false
        _:
            assert(false)
    yield(_enable_control.set_value(enable_control), "completed")

func move_to(pos: Vector2, rot: float) -> void:
    print("moving to ", pos, " ", rot)
    yield(set_control_mode(ControlMode.AUTO), "completed")
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
        yield(set_control_mode(ControlMode.MANUAL), "completed")

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

#func _on_rud_param_changed(name: String, value) -> void:
#    match name:
#        "enable_control":
#            var prev := control_mode
#            if value:
#                control_mode = ControlMode.AUTO
#            else:
#                control_mode = ControlMode.MANUAL
#            if prev != control_mode:
#                emit_signal("control_mode_changed", control_mode)
