extends RefCounted
class_name BrisklanceCentralDatabase

const FILE_NAME := "central_database.txt"
const HEAD_PLUGIN_REFERENCES_KEY := &"head_plugin_references"
const INSTALLED_PLUGINS_KEY := &"installed_plugin_mirrors"

var database := {}

var head_plugin_mirrors : Array[BrisklancePluginMirror] :
	set(p_value): database[HEAD_PLUGIN_REFERENCES_KEY] = p_value
	get: 
		var result : Array[BrisklancePluginMirror]
		result.assign(database.get_or_add(HEAD_PLUGIN_REFERENCES_KEY, []))
		return result

var installed_plugin_mirrors : Array[BrisklancePluginMirror] :
	set(p_value): database[INSTALLED_PLUGINS_KEY] = p_value
	get:
		var result : Array[BrisklancePluginMirror]
		result.assign(database.get_or_add(INSTALLED_PLUGINS_KEY, []))
		return result

static var singleton : BrisklanceCentralDatabase

static func get_singleton() -> BrisklanceCentralDatabase:
	if not singleton:
		singleton = BrisklanceCentralDatabase.new()
		singleton.load_database()
	return singleton

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
