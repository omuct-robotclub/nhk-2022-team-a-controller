extends Control


var cli_: RosBridge.Client
var launcher_buttons: Array


func _ready():
    var err := rosbridge.connect("connection_established", self, "_on_connection_established")

    launcher_buttons = $Launchers.get_children()
    for i in launcher_buttons.size():
        err = err || launcher_buttons[i].connect("pressed", self, "_on_button_pressed", [i])

    err = err || $ExpandButton.connect("pressed", self, "_on_expand_button_pressed")

    assert(err == OK)

func _on_expand_button_pressed():
    $Launchers.visible = true
    $ExpandButton.visible = false

func _input(event):
    if event is InputEventMouseMotion or event is InputEventMouseButton or \
       event is InputEventScreenTouch:
        if not $Launchers.get_global_rect().has_point(event.position):
            $Launchers.visible = false
            $ExpandButton.visible = true

#    elif Input.is_action_just_released("fire_0"):
#        _on_button_pressed(0)
#    elif Input.is_action_just_released("fire_1"):
#        _on_button_pressed(1)
#    elif Input.is_action_just_released("fire_2"):
#        _on_button_pressed(2)

func _on_connection_established():
    cli_ = rosbridge.create_client("/launch")

func _on_button_pressed(btn_idx):
    if cli_ == null: return

    var result = yield(cli_.call_service({ "index": btn_idx }), "completed")

    print(result)
