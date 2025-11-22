extends CanvasLayer

var enabled: bool = true
var watched_objects : Dictionary = {}

func _process(delta: float) -> void:
	if not enabled:
		$Text.text = ""
		return

	var txt := ""
	txt += "FPS: %s\n\n" % Engine.get_frames_per_second()

	for label_name in watched_objects.keys():
		var obj = watched_objects[label_name]
		txt += "=== %s ===\n" % label_name
		txt += get_object_debug_text(obj)
		txt += "\n"

	$Text.text = txt


func get_object_debug_text(obj: Object) -> String:
	var result := ""
	for prop in obj.get_property_list():
		var name: String = prop.name

		# Filtrar propiedades que no nos interesan
		if name.begins_with("_"):
			continue
		if name in ["script", "editor_description"]:
			continue

		var value = obj.get(name)
		result += "%s: %s\n" % [name, value]

	return result


func watch_object(name: String, object: Object) -> void:
	watched_objects[name] = object


func toggle():
	enabled = !enabled
