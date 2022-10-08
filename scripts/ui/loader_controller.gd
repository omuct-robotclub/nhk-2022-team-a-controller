tool
extends PanelContainer


export var loader_idx: int
export var loader_name: String setget set_loader_name
export var max_ammo: int setget set_max_ammo
export var reload_progress_color: Gradient

onready var _loader_state_sub := rosbridge.create_subscription("launcher_interfaces/LoaderStateArray", "/loader_state", funcref(self, "_loader_state_cb"))
onready var _notify_reload_cli :=  rosbridge.create_client("/notify_reloaded")
onready var _reload_cli := rosbridge.create_client("/reload")

onready var _ammo_indicator := $"%AmmoIndicator"
onready var _auto_reload := $"%AutoReload"
onready var _reload_button := $"%ReloadButton"
onready var _name := $"%Name"
onready var _status := $"%Status"

func _ready():
    _ammo_indicator.value = max_ammo
    var err := _ammo_indicator.connect("submit", self, "_on_ammo_indicator_submit")
    err = err || _auto_reload.connect("pressed", self, "_on_auto_reload_pressed")
    err = err || _reload_button.connect("pressed", self, "_on_reload_button_pressed")
    assert(err == OK)

func set_loader_name(name: String):
    loader_name = name
    if _name != null:
        _name.text = name

func set_max_ammo(v: int):
    if _ammo_indicator != null:
        _ammo_indicator.max_value = v
    max_ammo = v

const state_text := [
    ["READY", Color(0.0, 1.0, 0.0)],
    ["RELOADING: 25%", Color(1.0, 1.0, 0.0)],
    ["RELOADING: 75%", Color(1.0, 1.0, 0.0)]
]

func _loader_state_cb(msg: Dictionary):
    var is_ready: bool = msg["loader_states"][loader_idx]["is_ready"]
    var ammo_left: int = msg["loader_states"][loader_idx]["ammo_left"]
    var chamber_state: bool = msg["loader_states"][loader_idx]["chamber_state"]
    var reload_progress: float = msg["loader_states"][loader_idx]["reload_progress"]

    _status.text = "READY" if is_ready else "RELOADING: %3d%%" % (reload_progress * 100)
    _status.self_modulate = Color.green if is_ready else reload_progress_color.interpolate(reload_progress)
    _ammo_indicator.value = ammo_left
    _ammo_indicator.chamber_state = chamber_state

func _on_ammo_indicator_submit(n_ammo: int):
    if _notify_reload_cli == null: return

    _notify_reload_cli.call_service({
        "loader_idx": loader_idx,
        "ammo_left": n_ammo,
        "chamber_state": $"%AmmoIndicator".chamber_state
    })

func _on_auto_reload_pressed():
    robot.get_loader(loader_idx).auto_reload = _reload_button.pressed

func _on_reload_button_pressed():
    if _reload_cli != null:
        _reload_cli.call_service({
            "loader_idx": loader_idx
        })
