extends RefCounted
class_name BrisklanceCentralDatabase

const FILE_NAME := "central_database.txt"
const HEAD_PLUGIN_MIRRORS_KEY := &"head_plugin_mirrors"

var database := {}

var plugin_mirrors : Array :
	set(p_value): database[HEAD_PLUGIN_MIRRORS_KEY] = p_value
	get: return database.get_or_add(HEAD_PLUGIN_MIRRORS_KEY, [])

static var singleton : BrisklanceCentralDatabase

static func get_singleton() -> BrisklanceCentralDatabase:
	if not singleton:
		singleton = BrisklanceCentralDatabase.new()
		singleton.load_database()
	return singleton

func get_plugin_mirror_repository_names() -> Array:
	return plugin_mirrors.map(func(p_mirror: BrisklancePluginMirror) -> String:
		return p_mirror.repository_name
	)

func install(p_http_request: HTTPRequest) -> void:
	var existing_dependency_repository_name := []
	for plugin_mirror : BrisklancePluginMirror in plugin_mirrors:
		await plugin_mirror.install(p_http_request, existing_dependency_repository_name)

func generate_dependency_dictionary() -> Dictionary:
	var result := {}
	for mirror : BrisklancePluginMirror in plugin_mirrors:
		mirror.add_self_to_dependency_dictionary_recursively(result)
	return result

func get_database_file_path() -> String:
	var script := get_script() as Script
	if not script: return ""
	var file_path := script.resource_path.get_base_dir().path_join(FILE_NAME)
	return file_path

func load_database() -> void:
	var file_path := get_database_file_path()
	if file_path.is_empty(): return
	if not FileAccess.file_exists(file_path): return
	var file := FileAccess.open(file_path, FileAccess.READ)
	var parsed_content := str_to_var(file.get_as_text())
	if typeof(parsed_content) != TYPE_DICTIONARY: return
	database = parsed_content

func save_database() -> void:
	var file_path := get_database_file_path()
	if file_path.is_empty(): return
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(var_to_str(database))
	file.flush()
