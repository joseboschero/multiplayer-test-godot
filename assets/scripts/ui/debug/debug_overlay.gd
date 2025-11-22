extends CanvasLayer

var enabled: bool = true
var watched_objects : Dictionary = {}

@export var show_fps: bool = true
@export var show_physics: bool = true
@export var show_memory: bool = true
@export var show_render: bool = true
@export var show_objects: bool = true

func _process(delta):
	if not enabled:
		$Text.text = ""
		return

	var txt = ""
	
	# Métricas base de rendimiento
	# Sección FPS
	if show_fps:
		txt += "FPS: %d\n" % Engine.get_frames_per_second()

	# Sección Physics
	if show_physics:
		txt += "Physics ms: %.2f\n" % (Performance.get_monitor(Performance.Monitor.TIME_PHYSICS_PROCESS) * 1000)

	# Sección Memoria
	if show_memory:
		txt += "Memory (MB): %.2f\n" % (Performance.get_monitor(Performance.Monitor.MEMORY_STATIC) / 1024.0 / 1024.0)

	# Sección Render
	if show_render:
		txt += "Triangles: %d\n" % Performance.get_monitor(Performance.Monitor.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		txt += "Draw Calls: %d\n" % Performance.get_monitor(Performance.Monitor.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		txt += "Frame ms: %.2f\n" % (Performance.get_monitor(Performance.Monitor.TIME_PROCESS) * 1000)

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
	
	# Ajustar ColorRect al Label
	var padding = Vector2(5, -20)
	var size = $Text.get_minimum_size() + padding
	$Background.size = size


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
