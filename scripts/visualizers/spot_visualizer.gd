extends Node2D


const spot_scenes := {
    0: preload("res://scenes/spot_a.tscn"),
    1: preload("res://scenes/spot_b.tscn"),
    2: preload("res://scenes/runway.tscn"),
    3: preload("res://scenes/base_a.tscn"),
    4: preload("res://scenes/base_b.tscn")
}

const launcher_popup_menu = preload("res://scenes/launcher_popup_menu.tscn")

onready var _spot_info_sub := rosbridge.create_subscription("spot_info_interfaces/SpotInfoArray", "/spot_info", funcref(self, "_spot_info_callback"))
onready var _launcher_spec_sub := rosbridge.create_subscription("launcher_interfaces/LauncherSpecArray", "/launcher_specs", funcref(self, "_launcher_spec_callback"))
onready var _goal_pose_pub := rosbridge.create_publisher("geometry_msgs/PoseStamped", "/goal_pose")

var _spots: Array
var _launchers: Array

func _ready() -> void:
    pass

func _spot_info_callback(msg: Dictionary) -> void:
    for spot in _spots:
        spot.queue_free()
    _spots.clear()

    var i = 0
    for spot_info in msg["spots"]:
        if spot_info["spot_type"] in spot_scenes.keys():
            var spot = spot_scenes[int(spot_info["spot_type"])].instance()
            spot.position = Vector2(spot_info["pose"]["x"], spot_info["pose"]["y"])
            spot.rotation = spot_info["pose"]["theta"]
            spot.spot_type = int(spot_info["spot_type"])
            spot.has_angle_limit = spot_info["has_angle_limit"]
            spot.angle_min = spot_info["angle_min"]
            spot.angle_max = spot_info["angle_max"]
            _spots.push_back(spot)
            spot.connect("input_event", self, "_on_spot_input_event", [i])
            add_child(spot)
            i += 1

func _launcher_spec_callback(msg: Dictionary) -> void:
    _launchers = msg["specs"]

func _on_spot_input_event(event, index) -> void:
    if event is InputEventScreenTouch:
        if event.pressed == true:
            _create_popup(event.position, index)

func _create_popup(position: Vector2, spot_idx: int) -> void:
    if spot_idx >= _spots.size():
        return

    var spot = _spots[spot_idx]

    var compatible_launchers := []
    for launcher in _launchers:
        if spot.spot_type in launcher["compatible_spot_types"]:
            compatible_launchers.push_back(launcher)

    var menu := PopupMenu.new()
    menu.rect_scale *= 2.0
    for launcher in compatible_launchers:
        menu.add_item(launcher["name"])
    var err := menu.connect("index_pressed", self, "_on_menu_index_pressed", [spot, compatible_launchers, menu])
    assert(err == OK)

    $CanvasLayer.add_child(menu)
    menu.set_global_position(position)
    menu.popup()

func _on_menu_index_pressed(index: int, spot, compatible_launchers, menu) -> void:
    menu.queue_free()

    var launcher = compatible_launchers[index]
    var sel := LaunchPositionSelector.new(launcher, spot)
    var err := sel.connect("launch_position_selected", self, "_on_launch_position_selected")
    assert(err == OK)
    add_child(sel)

func _on_launch_position_selected(pos: Vector2, angle: float) -> void:
    yield(rosbridge.set_parameter("/rud_controller_node",
                                  "enable_control",
                                  true),
          "completed")
    var ori = Quat(Vector3(0, 0, 1), angle)
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
    _goal_pose_pub.publish(msg)
    print("goal pose published: ", pos, " ", angle)
