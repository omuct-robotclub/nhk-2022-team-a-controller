extends PanelContainer

const GainControl = preload("res://scripts/gain_control.gd")
export var pid_name := ""

export var ff_max := 1.0
export var kp_max := 1.0
export var ki_max := 1.0
export var kd_max := 1.0

onready var _label := $"%Label"
onready var _ff := $"%FFGain"
onready var _p := $"%PGain"
onready var _i := $"%IGain"
onready var _d := $"%DGain"

var _pid: Robot.PidController

func _ready() -> void:
    _label.text = pid_name
    _pid = robot.get_pid(pid_name)
    var err := _pid.kp.connect("value_updated", self, "_on_pid_gain_updated", [_p])
    err = err || _pid.ki.connect("value_updated", self, "_on_pid_gain_updated", [_i])
    err = err || _pid.kd.connect("value_updated", self, "_on_pid_gain_updated", [_d])
    err = err || _pid.ff.connect("value_updated", self, "_on_pid_gain_updated", [_ff])

    err = err || _p.connect("gain_updated", self, "_on_slider_gain_updated", [_pid.kp])
    err = err || _i.connect("gain_updated", self, "_on_slider_gain_updated", [_pid.ki])
    err = err || _d.connect("gain_updated", self, "_on_slider_gain_updated", [_pid.kd])
    err = err || _ff.connect("gain_updated", self, "_on_slider_gain_updated", [_pid.ff])

    _p.max_value = kp_max
    _i.max_value = ki_max
    _d.max_value = kd_max
    _ff.max_value = ff_max

    assert(err == OK)

func _on_pid_gain_updated(new_value: float, g: GainControl) -> void:
    g.value = new_value

func _on_slider_gain_updated(new_value: float, p: RosBridge.Parameter) -> void:
    print(new_value)
    p.set_value(new_value)
