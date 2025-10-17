@tool
extends RefCounted
class_name BrisklancePluginMirror

const ZIP_FILE_NAME := "brisklance_module.zip"
const MODULES_DIRECTORY_NAME := "plugins"

var repository_name : String
var repository_tag : String

static func create(p_repository_name: String, p_repository_tag: String) -> BrisklancePluginMirror:
	var result := BrisklancePluginMirror.new()
	result.repository_name = p_repository_name
	result.repository_tag = p_repository_tag
	return result

func create_mirror_url() -> String:
	return "https://github.com/{repository_name}/releases/download/{repository_tag}/{zip_file_name}".format({
		"repository_name": repository_name,
		"repository_tag": repository_tag,
		"zip_file_name": ZIP_FILE_NAME
	})

func get_plugin_directory_path() -> String:
	return BrisklanceEditorPlugin.BRISKLANCE_DIRECTORY_PATH.path_join(MODULES_DIRECTORY_NAME).path_join(repository_name)

func purge() -> void:
	DirAccess.remove_absolute(get_plugin_directory_path())

func retreive() -> BrisklancePluginReference:
	var plugin_directory_path := get_plugin_directory_path()
	var plugin_reference := BrisklancePluginReference.find(plugin_directory_path)
	if plugin_reference: return plugin_reference
	
	var client := HTTPClient.new()
	var headers := []
	var connection_status := client.request(HTTPClient.METHOD_GET, create_mirror_url(), headers)
	if connection_status != OK:
		printerr("Unable to retrieve '{repository_name}' (tag: '{repository_tag}')".format({
			"repository_name": repository_name,
			"repository_tag": repository_tag
		}))
		return null
	var zip_file_data = PackedByteArray()
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		client.poll()
		if client.get_response_body_length() <= 0: continue
		zip_file_data.append_array(client.read_response_body_chunk())
	var temp_directory := DirAccess.create_temp()
	var zip_file_path := temp_directory.get_current_dir().path_join(ZIP_FILE_NAME)
	var zip_file := FileAccess.open(zip_file_path, FileAccess.WRITE)
	zip_file.store_buffer(zip_file_data)
	zip_file.close()
	var zip_reader := ZIPReader.new()
	zip_reader.open(zip_file_path)
	DirAccess.make_dir_recursive_absolute(plugin_directory_path)
	var plugin_directory := DirAccess.open(plugin_directory_path)
	
	var file_subpaths = zip_reader.get_files()
	for file_subpath in file_subpaths:
		if file_subpath.ends_with("/"):
			plugin_directory.make_dir_recursive(file_subpath)
			continue
		var target_file_path := plugin_directory.get_current_dir().path_join(file_subpath)
		plugin_directory.make_dir_recursive(target_file_path.get_base_dir())
		var target_file = FileAccess.open(target_file_path, FileAccess.WRITE)
		var target_file_content = zip_reader.read_file(file_subpath)
		target_file.store_buffer(target_file_content)
	
	plugin_reference = BrisklancePluginReference.find(plugin_directory_path)
	var newly_installed_plugin_mirrors : Array[BrisklancePluginMirror]
	
	for dependency_repository_name in plugin_reference.dependencies.keys():
		for mirror in BrisklanceCentralDatabase.get_singleton().head_plugin_mirrors:
			if mirror.repository_name == dependency_repository_name: continue
		
		for mirror in newly_installed_plugin_mirrors:
			if mirror.repository_name == dependency_repository_name:
				printerr("'{0}' has already been installed by another plugin. Please install the plugin of acceptable version manually.")
				for newly_installed in newly_installed_plugin_mirrors: 
					newly_installed.purge()
				purge()
				return null
		
		for mirror in BrisklanceCentralDatabase.get_singleton().installed_plugin_mirrors:
			if mirror.repository_name == dependency_repository_name:
				printerr("'{0}' has already been installed by another plugin. Please install the plugin of acceptable version manually.")
				for newly_installed in newly_installed_plugin_mirrors: 
					newly_installed.purge()
				purge()
				return null
		
		var depencency := BrisklancePluginMirror.create(dependency_repository_name, plugin_reference.dependencies[dependency_repository_name])
		var dependency_plugin_reference := depencency.retreive()
		if not dependency_plugin_reference:
			printerr("'{0}' cannot be installed due to '{1}'.".format([repository_name, dependency_repository_name]))
			for newly_installed in newly_installed_plugin_mirrors: 
				newly_installed.purge()
			purge()
			return null
		
		newly_installed_plugin_mirrors.push_back(depencency)
	
	BrisklanceCentralDatabase.get_singleton().installed_plugin_mirrors.append_array(newly_installed_plugin_mirrors)
	BrisklanceCentralDatabase.get_singleton().save_database()
	
	return plugin_reference
