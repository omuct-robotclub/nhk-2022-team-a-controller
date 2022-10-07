extends Node2D
class_name TFFrame

export var is_root := true
export var frame_id: String
var _tf_static_sub: RosBridge.Subscription
var _tf_sub: RosBridge.Subscription

func _ready():
    yield(rosbridge, "connection_established")
    if not is_root:
        _tf_static_sub = rosbridge.create_subscription("tf2_msgs/msg/TFMessage", "/tf_static", funcref(self, "tf_callback"))
        _tf_sub = rosbridge.create_subscription("tf2_msgs/msg/TFMessage", "/tf", funcref(self, "tf_callback"), 10)

func get_frame_id() -> String:
    return frame_id

func get_parent_frame() -> String:
    if get_parent().has_method("get_frame_id"):
        return get_parent().get_frame_id()
    return ""

func tf_callback(msg: Dictionary):
    for tf in msg["transforms"]:
        if tf["header"]["frame_id"] == get_parent_frame() and tf["child_frame_id"] == frame_id:
            position.x = tf["transform"]["translation"]["x"]
            position.y = tf["transform"]["translation"]["y"]
            var q = Quat(tf["transform"]["rotation"]["x"], tf["transform"]["rotation"]["y"], tf["transform"]["rotation"]["z"], tf["transform"]["rotation"]["w"])
            rotation = q.get_euler().z
