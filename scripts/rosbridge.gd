extends Node
class_name RosBridge

export var url := ""

var _serial_id := 0
var _subscription_callbacks: Dictionary
var _advertises: Dictionary

var _prev_total_download := 0
var _prev_total_upload := 0

var _transports: Array
var _current_transport: Transport

var download_speed := 0.0 setget , get_download_speed
var upload_speed := 0.0 setget , get_upload_speed

signal connection_established()
signal disconnected()
signal service_response(id, values)
signal transport_changed()

func get_download_speed():
    return download_speed

func get_upload_speed():
    return upload_speed

func add_transport(t: Transport) -> void:
    _transports.push_back(t)

func _ready():
    var tim := Timer.new()
    add_child(tim)
    tim.wait_time = 1.0
    tim.one_shot = false
    var err := tim.connect("timeout", self, "_update_net_stat")
    tim.start()

    err = err || connect("transport_changed", self, "_on_self_transport_changed")

    assert(err == OK)

func _process(_delta):
    for t in _transports:
        t.poll()
    update_transport()

func update_transport():
    var is_transport_avail = _current_transport != null

    if _current_transport != null and not _current_transport.is_ready():
        _current_transport.disconnect("msg_received", self, "_on_msg_received")
        _current_transport = null

    if _current_transport == null:
        for t in _transports:
            if t.is_ready():
                _current_transport = t
                var err := _current_transport.connect("msg_received", self, "_on_msg_received")
                assert(err == OK)
                emit_signal("transport_changed")

    if is_transport_avail and _current_transport == null:
        print("Disconnected. No alternative transport is available.")
        emit_signal("disconnected")

func _on_self_transport_changed():
    emit_signal("connection_established")
    print("transport was changed to " + _current_transport.get_name())

    # readvertise
    for adv in _advertises.values():
        for content in adv.values():
            _send(content)

    for sub in _subscription_callbacks.values():
        for ssub in sub.values():
            _send(ssub.content)
            print(ssub.content)

func _update_net_stat():
    if _current_transport != null:
        var ratio := 1.0
        download_speed = download_speed * (1.0 - ratio) + ((_current_transport.get_total_download() - _prev_total_download) / 1.0) * ratio
        upload_speed = upload_speed * (1.0 - ratio) + ((_current_transport.get_total_upload() - _prev_total_upload) / 1.0) * ratio
        _prev_total_download = _current_transport.get_total_download()
        _prev_total_upload = _current_transport.get_total_upload()

func _get_serial_id() -> String:
    _serial_id += 1
    return str(_serial_id)

func _on_msg_received(d):
    if d["op"] == "publish":
        if _subscription_callbacks.has(d["topic"]):
            for v in _subscription_callbacks[d["topic"]].values():
                v.cb.call_func(d["msg"])
    elif d["op"] == "service_response":
        emit_signal("service_response", d["id"], d["values"])

func _send(d: Dictionary):
    if _current_transport != null:
        _current_transport.send(d)

func _advertise(id: String, topic: String, type: String):
    var content = { "op": "advertise", "id": id, "topic": topic, "type": type }

    if _advertises.has(topic):
        _advertises[topic][id] = content
    else:
        _advertises[topic] = {id: content}
    _send(content)

func _unadvertise(id: String, topic: String):
    _advertises[topic].erase(id)
    if _advertises[topic].empty():
        var content = { "op": "unadvertise", "id": id, "topic": topic }
        _send(content)

func _publish(id: String, topic: String, msg: Dictionary):
    var content = { "op": "publish", "id": id, "topic": topic, "msg": msg}
    _send(content)

func _subscribe(callback: FuncRef, id: String, topic: String, type: String, throttle_rate:=0, queue_length:=0):
    var content = { "op": "subscribe", "id": id, "topic": topic, "type": type, "throttle_rate": throttle_rate, "queue_length": queue_length}
    if _subscription_callbacks.has(topic):
        _subscription_callbacks[topic][id] = {"cb": callback, "content": content}
    else:
        _subscription_callbacks[topic] = {id: {"cb": callback, "content": content}}

    _send(content)

func _unsubscribe(id: String, topic: String):
    _subscription_callbacks[topic].erase(id)
    if _subscription_callbacks[topic].empty():
        var content = { "op": "unsubscribe", "id": id, "topic": topic}
        _send(content)

func _call_service(id: String, service: String, args):
    var content = { "op": "call_service", "service": service, "id": id,  "args": args}
    _send(content)
    while true:
        var res = yield(self, "service_response")
#		print("res: ", res)
        if res[0] == id:
            return res[1]

class Publisher:
    var _id: String
    var _bridge: RosBridge
    var _topic: String

    func publish(msg: Dictionary):
        _bridge._publish(_id, _topic, msg)

    func _notification(what):
        if what == NOTIFICATION_PREDELETE:
            _bridge._unadvertise(_id, _topic)

func create_publisher(type: String, topic: String) -> Publisher:
    var result = Publisher.new()
    result._id = _get_serial_id()
    result._bridge = self
    result._topic = topic
    _advertise(result._id, topic, type)
    return result

class Subscription:
    var _id: String
    var _bridge: RosBridge
    var _topic: String

    func _notification(what):
        if what == NOTIFICATION_PREDELETE:
            if is_instance_valid(_bridge):
                _bridge._unsubscribe(_id, _topic)

func create_subscription(type: String, topic: String, callback: FuncRef, throttle_rate:=0, queue_length:=0) -> Subscription:
    var result = Subscription.new()
    result._id = _get_serial_id()
    result._bridge = self
    result._topic = topic
    _subscribe(callback, result._id, topic, type, throttle_rate, queue_length)
    return result

class Client:
    var _bridge: RosBridge
    var _service: String

    func call_service(args: Dictionary):
        return _bridge._call_service(_bridge._get_serial_id(), _service, args)

func create_client(service: String) -> Client:
    var result = Client.new()
    result._bridge = self
    result._service = service
    return result

const type_to_param_type_lut = {
    TYPE_BOOL: [1, "bool_value"],
    TYPE_INT: [2, "interger_value"],
    TYPE_REAL: [3, "double_value"],
    TYPE_STRING: [4, "string_value"],
}

const param_type_to_type_lut = {
    1: "bool_value",
    2: "interger_value",
    3: "double_value",
    4: "string_value",
}

func set_parameter(node_name: String, param_name: String, value):
    var cli = create_client(node_name + "/set_parameters")

    assert(type_to_param_type_lut.has(typeof(value)), "unsupported type")

    var type_id = type_to_param_type_lut[typeof(value)][0]
    var value_name = type_to_param_type_lut[typeof(value)][1]

    yield(cli.call_service({
        "parameters": [
            {
                "name": param_name,
                "value": {
                    "type": type_id,
                    value_name: value
                }
            }
        ]
    }), "completed")

func get_parameter(node_name: String, param_name: String):
    var cli = create_client(node_name + "/set_parameters")

    var resp = yield(cli.call_service({
        "names": [param_name],
    }), "completed")

    if resp["values"].size() == 0:
        push_error("parameter " + param_name + " not fonund")
        return

    var p = resp["values"][0]

    var field_name = param_type_to_type_lut[p["type"]]

    return p[field_name]


onready var _param_event_sub = create_subscription("rcl_interfaces/ParameterEvent", "/parameter_events", funcref(self, "_param_event_callback"))
var _param_event_callbacks: Dictionary

func _param_event_callback(msg: Dictionary) -> void:
    var node_name = msg["node"]
    if not _param_event_callbacks.has(node_name): return
    for id in _param_event_callbacks[node_name]:
        for p in msg["changed_parameters"]:
            _param_event_callbacks[node_name][id].call_func(p["name"], p["value"][param_type_to_type_lut[int(p["value"]["type"])]])

func _register_param_event_callback(cb: FuncRef, node_name: String) -> String:
    var id = _get_serial_id()
    if _param_event_callbacks.has(node_name):
        _param_event_callbacks[node_name][id] = cb
    else:
        _param_event_callbacks[node_name] = { id: cb }
    return id

func _unregister_param_event_callback(id: String, node_name: String) -> void:
    _param_event_callbacks[node_name].erase(id)

class ParameterEventHandler extends Reference:
    var _br: RosBridge
    var _node_name: String
    var _id: String

    func _init(br: RosBridge, id: String, node_name: String) -> void:
        _br = br
        _node_name = node_name
        _id = id

    func _notification(what: int) -> void:
        if what == NOTIFICATION_PREDELETE:
            _br._unregister_param_event_callback(_id, _node_name)

func create_parameter_event_handler(node_name: String, callback: FuncRef) -> ParameterEventHandler:
    return ParameterEventHandler.new(self, _register_param_event_callback(callback, node_name), node_name)
