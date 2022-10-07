extends Node2D


var _sub: RosBridge.Subscription
var _msg: Dictionary
var _image := Image.new()
var _texture := ImageTexture.new()


func _ready():
    var err := rosbridge.connect("connection_established", self, "_on_connection_established")
    assert(err == OK)

func _on_connection_established():
    _sub = rosbridge.create_subscription("nav_msgs/OccupancyGrid", "/map", funcref(self, "msg_callback"))

func update_texture():
    var width = int(_msg["info"]["width"])
    var height = int(_msg["info"]["height"])
    var data = _msg["data"]

    _image.create(width, height, false, Image.FORMAT_L8)
    _image.lock()

    for i in range(len(data)):
        var x = i % width
        var y = i / width

        _image.set_pixel(x, y, Color8(100 - data[i], 0, 0))

    _image.unlock()

    _texture.create_from_image(_image)

func msg_callback(msg: Dictionary):
    _msg = msg
    print("map data received")
    update_texture()
    update()

func _draw():
    if _msg.empty(): return

    var resolution = _msg["info"]["resolution"]
    var width = int(_msg["info"]["width"])
    var height = int(_msg["info"]["height"])
    var offset = Vector2(_msg["info"]["origin"]["position"]["x"], _msg["info"]["origin"]["position"]["y"])
    draw_texture_rect(_texture, Rect2(offset.x, offset.y, width * resolution, height * resolution), false)

