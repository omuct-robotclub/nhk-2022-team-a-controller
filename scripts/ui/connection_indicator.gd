extends VBoxContainer


onready var _connection_state := $"%ConnectionState"
onready var _download := $"%Download"
onready var _upload := $"%Upload"


func _ready() -> void:
    var err := rosbridge.connect("connection_established", self, "_on_connection_established")
    err = err || rosbridge.connect("disconnected", self, "_on_disconnected")

    assert(err == OK)

func _on_connection_established() -> void:
    _connection_state.self_modulate = Color.green
    _connection_state.text = "Connected"

func _on_disconnected() -> void:
    _connection_state.self_modulate = Color.red
    _connection_state.text = "Disconnected"

func _process(_delta: float) -> void:
    _download.text = str(rosbridge.download_speed)
    _upload.text = str(rosbridge.upload_speed)
