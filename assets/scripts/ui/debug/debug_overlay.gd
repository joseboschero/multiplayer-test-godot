extends CanvasLayer

var enabled: bool = true
var watched_objects : Dictionary = {}

func _process(delta):
	if not enabled:
		$Text.text = ""
		return

	var txt = ""
	txt += "FPS: %s\n\n" % Engine.get_frames_per_second()

	for label_name in watched_objects.keys():
		var obj = watched_objects[label_name]

		# Si es un callable (watch_value)
		if obj is Callable:
			txt += "%s: %s\n" % [label_name, obj.call()]
			continue

		# Si es un objeto (watch_object)
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

func watch_value(name: String, callable: Callable) -> void:
	watched_objects[name] = callable

func toggle():
	enabled = !enabled
