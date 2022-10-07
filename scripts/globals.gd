extends Node


onready var ui: Control = get_node(NodePath("/root/Main/CanvasLayer/Ui"))
onready var visualization: Node2D = get_node("/root/Main/Visualization")


func _ready() -> void:
    assert(ui != null)
    assert(visualization != null)
