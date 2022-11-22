extends Control


var launcher_buttons: Array


func _ready():
    var err := OK
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

func _on_button_pressed(btn_idx):
    robot.get_launcher(btn_idx).launch()
