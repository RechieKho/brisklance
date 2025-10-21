@tool
extends RefCounted
class_name BrisklancePluginReference

const SELF_ADDON_DIRECTORY_NAME := "self"
const CONFIGURATION_FILE_NAME := "plugin.cfg"
const PLUGIN_SECTION_KEY := &"plugin"
const BRISKLANCE_SECTION_KEY := &"brisklance"
const NAME_KEY := &"name"
const DEPENDENCY_DICTIONARY_KEY := &"dependencies"

var configuration_file_path : String
var configuration : ConfigFile

var name : String :
	set(p_value): configuration.set_value(PLUGIN_SECTION_KEY, NAME_KEY, p_value)
	get: return configuration.get_value(PLUGIN_SECTION_KEY, NAME_KEY, "")

var dependency_dictionary : Dictionary :
	set(p_value): configuration.set_value(BRISKLANCE_SECTION_KEY, DEPENDENCY_DICTIONARY_KEY, p_value)
	get:
		if not configuration.has_section_key(BRISKLANCE_SECTION_KEY, DEPENDENCY_DICTIONARY_KEY):
			configuration.set_value(BRISKLANCE_SECTION_KEY, DEPENDENCY_DICTIONARY_KEY, {})
		return configuration.get_value(BRISKLANCE_SECTION_KEY, DEPENDENCY_DICTIONARY_KEY)

static func find(p_directory_path: String) -> BrisklancePluginReference:
	var file_path := p_directory_path.path_join(CONFIGURATION_FILE_NAME)
	if FileAccess.file_exists(file_path):
		var result := BrisklancePluginReference.new()
		result.configuration_file_path = file_path
		result.load_configuration()
		return result
	
	var directory := DirAccess.open(p_directory_path)
	if not directory: return null
	for child_directory_name in directory.get_directories():
		var child_directory_path := p_directory_path.path_join(child_directory_name)
		var result := find(child_directory_path)
		if result: return result
	
	return null

static func load_self_plugin_reference() -> BrisklancePluginReference:
	var file_path := BrisklanceEditorPlugin.BRISKLANCE_DIRECTORY_PATH.path_join(SELF_ADDON_DIRECTORY_NAME).path_join(CONFIGURATION_FILE_NAME)
	if not FileAccess.file_exists(file_path): return null
	var result := BrisklancePluginReference.new()
	result.configuration_file_path = file_path
	result.load_configuration()
	return result

func load_configuration() -> void:
	if configuration_file_path.is_empty(): return 
	configuration = ConfigFile.new()
	configuration.load(configuration_file_path)

func save_configuration() -> void:
	if not configuration: configuration = ConfigFile.new()
	configuration.save(configuration_file_path)
