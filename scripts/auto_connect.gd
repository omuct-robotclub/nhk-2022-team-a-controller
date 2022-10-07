extends Node

const WebsocketTransport = preload("res://scripts/transports/websocket_transport.gd")
# const SerialTransport = preload("res://scripts/transports/serial_transport.gd")
# const IM920Transport = preload("res://scripts/transports/im920_transport.gd")

func _ready():
    var ws := WebsocketTransport.new()
    ws.open()
    rosbridge.add_transport(ws)

#    var im920 := IM920Transport.new()
#    im920.open()
#    rosbridge.add_transport(im920)

#    var ser := SerialTransport.new()
#    ser.open()
#    rosbridge.add_transport(ser)
