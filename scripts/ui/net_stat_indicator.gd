extends VBoxContainer


onready var _download_text: String = $DownloadSpeed.text
onready var _upload_text: String = $UploadSpeed.text


func _process(_delta):
    $DownloadSpeed.text = _download_text + str(rosbridge.download_speed)
    $UploadSpeed.text = _upload_text + str(rosbridge.upload_speed)
