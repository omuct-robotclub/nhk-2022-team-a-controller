tool
extends PanelContainer


export var loader_idx: int
export var loader_name: String setget set_loader_name
export var max_ammo: int setget set_max_ammo
export var reload_progress_color: Gradient

var _loader_state_sub: rosbridge.Subscription
var _notify_reload_cli: rosbridge.Client
var _reload_cli: rosbridge.Client

func _ready():
    $"%AmmoIndicator".value = max_ammo
    var err := rosbridge.connect("connection_established", self, "_on_connection_established")
    err = err || $"%AmmoIndicator".connect("submit", self, "_on_ammo_indicator_submit")
    err = err || $"%AutoReload".connect("pressed", self, "_on_auto_reload_pressed")
    err = err || $"%ReloadButton".connect("pressed", self, "_on_reload_button_pressed")
    assert(err == OK)

func set_loader_name(name: String):
    loader_name = name
    if $"%Name" != null:
        $"%Name".text = name

func set_max_ammo(v: int):
    if $"%AmmoIndicator" != null:
        $"%AmmoIndicator".max_value = v
    max_ammo = v

func _on_connection_established():
    _loader_state_sub = rosbridge.create_subscription("launcher_interfaces/LoaderStateArray", "/loader_state", funcref(self, "_loader_state_cb"))
    _notify_reload_cli = rosbridge.create_client("/notify_reloaded")
    _reload_cli = rosbridge.create_client("/reload")

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

    $"%Status".text = "READY" if is_ready else "RELOADING: %3d%%" % (reload_progress * 100)
    $"%Status".self_modulate = Color.green if is_ready else reload_progress_color.interpolate(reload_progress)
    $"%AmmoIndicator".value = ammo_left
    $"%AmmoIndicator".chamber_state = chamber_state

func _on_ammo_indicator_submit(n_ammo: int):
    if _notify_reload_cli == null: return

    _notify_reload_cli.call_service({
        "loader_idx": loader_idx,
        "ammo_left": n_ammo,
        "chamber_state": $"%AmmoIndicator".chamber_state
    })

func _on_auto_reload_pressed():
    rosbridge.set_parameter("nhka_hardware_node", "loader" + str(loader_idx) + ".auto_reload", $"%AutoReload".pressed)

func _on_reload_button_pressed():
    if _reload_cli != null:
        _reload_cli.call_service({
            "loader_idx": loader_idx
        })
