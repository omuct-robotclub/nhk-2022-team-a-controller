extends VBoxContainer

export var format_text := "%5.2f"
var _sub := rosbridge.create_subscription("geometry_msgs/Pose2D", "/robot_pose", funcref(self, "_callback"))


func _callback(msg: Dictionary) -> void:
    var x_text = format_text % msg["x"]
    var y_text = format_text % msg["y"]
    var theta_text = format_text % rad2deg(msg["theta"])

    $X/Indicator.text = x_text
    $Y/Indicator.text = y_text
    $Theta/Indicator.text = theta_text
