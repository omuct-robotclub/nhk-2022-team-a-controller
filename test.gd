extends Node
#
#var _port: Serial.Port = null
#
#func _ready():
#    pass
#
#func _process(_delta):
#    if _port == null:
#        var ports := serial.get_ports()
#
#        if ports.size() == 0:
#            return
#
#        var port: Serial.Port = null
#        for p in ports:
#            if p.name == "/dev/ttyUSB0":
#                port = p
#                break
#
#        if port == null:
#            return
#
#        print("open")
#        var res := port.open(115200)
#        if res != OK:
#            return
#
#        _port = port
#
#    var data := PoolByteArray()
#    for i in range(0x41, 0x5b):
#        data.append(i)
#
#    var wres := _port.write(data)
#    assert(wres == OK)
#
#    var rres := _port.read()
#    var text := rres.get_string_from_ascii()
#    if text.length() > 0:
#        print(text)
