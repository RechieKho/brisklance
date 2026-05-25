extends RefCounted
class_name BrisklanceLocalDevelopmentStore

const FILE_NAME := "local_development_store.txt"
const GITHUB_API_KEY_KEY := &"github_api_key"

var store := {}

var github_api_key : String :
	set(p_value): store[GITHUB_API_KEY_KEY] = p_value
	get: return store.get_or_add(GITHUB_API_KEY_KEY, "")

static var singleton : BrisklanceLocalDevelopmentStore

static func get_singleton() -> BrisklanceLocalDevelopmentStore:
	if not singleton:
		singleton = BrisklanceLocalDevelopmentStore.new()
		singleton.load_store()
	return singleton

func get_database_file_path() -> String:
	var script := get_script() as Script
	if not script: return ""
	var file_path := script.resource_path.get_base_dir().path_join(FILE_NAME)
	return file_path

func load_store() -> void:
	var file_path := get_database_file_path()
	if file_path.is_empty(): return
	if not FileAccess.file_exists(file_path): return
	var file := FileAccess.open(file_path, FileAccess.READ)
	var parsed_content := str_to_var(file.get_as_text())
	if typeof(parsed_content) != TYPE_DICTIONARY: return
	store = parsed_content

func save_store() -> void:
	var file_path := get_database_file_path()
	if file_path.is_empty(): return
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(var_to_str(store))
	file.flush()
