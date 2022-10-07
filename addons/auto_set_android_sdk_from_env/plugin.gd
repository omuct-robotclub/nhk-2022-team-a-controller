tool
extends EditorPlugin

var original_sdk_path: String
var restore := false
var settings := get_editor_interface().get_editor_settings()

func _enter_tree() -> void:
	original_sdk_path = settings.get_setting("export/android/android_sdk_path")
	
	var android_home := OS.get_environment("ANDROID_HOME")
	if android_home != "":
		settings.set_setting("export/android/android_sdk_path", android_home)
		restore = true
	
	settings.connect("settings_changed", self, "_on_settings_changed")

func _exit_tree() -> void:
	if restore:
		settings.set_setting("export/android/android_sdk_path", original_sdk_path)

func _on_settings_changed() -> void:
	if settings.get_setting("export/android/android_sdk_path") != original_sdk_path:
		restore = false
