@tool
extends RefCounted
class_name BrisklancePluginMirror

const ZIP_FILE_NAME := "brisklance_module.zip"
const PLUGINS_DIRECTORY_NAME := "plugins"

var repository_name : String
var repository_tag : String
var installed_dependent_plugin_mirrors : Array

static func remove_directory_recursively(p_directory_path: String) -> void:
	var directory := DirAccess.open(p_directory_path)
	
	for child_file_name in directory.get_files():
		var child_file_path := p_directory_path.path_join(child_file_name)
		DirAccess.remove_absolute(child_file_path)
	
	for child_directory_name in directory.get_directories():
		var child_directory_path := p_directory_path.path_join(child_directory_name)
		remove_directory_recursively(child_directory_path)
	
	DirAccess.remove_absolute(p_directory_path)

static func create(p_repository_name: String, p_repository_tag: String) -> BrisklancePluginMirror:
	var result := BrisklancePluginMirror.new()
	result.repository_name = p_repository_name
	result.repository_tag = p_repository_tag
	return result

func get_mirror_url() -> String:
	return "https://github.com/{repository_name}/releases/download/{repository_tag}/{zip_file_name}".format({
		"repository_name": repository_name,
		"repository_tag": repository_tag,
		"zip_file_name": ZIP_FILE_NAME
	})

func get_plugin_directory_path() -> String:
	return BrisklanceEditorPlugin.BRISKLANCE_DIRECTORY_PATH.path_join(PLUGINS_DIRECTORY_NAME).path_join(str(hash(repository_name)))

func purge() -> void:
	BrisklanceCentralDatabase.get_singleton().installed_plugin_mirrors = BrisklanceCentralDatabase.get_singleton().installed_plugin_mirrors.filter(func(p_mirror: BrisklancePluginMirror) -> bool:
		return not p_mirror in installed_dependent_plugin_mirrors
	)
	BrisklanceCentralDatabase.get_singleton().save_database()
	for mirror : BrisklancePluginMirror in installed_dependent_plugin_mirrors:
		mirror.purge()
	remove_directory_recursively(get_plugin_directory_path())


func retreive(p_http_request: HTTPRequest) -> BrisklancePluginReference:
	var plugin_directory_path := get_plugin_directory_path()
	var plugin_reference := BrisklancePluginReference.find(plugin_directory_path)
	if plugin_reference: return plugin_reference
	
	var mirror_url := get_mirror_url()
	var temp_directory := DirAccess.create_temp(str(hash(repository_name)))
	var zip_file_path := temp_directory.get_current_dir().path_join(ZIP_FILE_NAME)
	p_http_request.download_file = zip_file_path
	var request_status := p_http_request.request(mirror_url, PackedStringArray(), HTTPClient.METHOD_GET)
	if request_status != OK:
		printerr("Fail to download '{0}' from '{1}' (Error: {2}).".format([repository_name, mirror_url, error_string(request_status)]))
		return null
	print("Downloading '{0}'.".format([repository_name]))
	await p_http_request.request_completed as Array
	print("'{0}' downloaded.".format([repository_name]))

	print("Unzipping '{0}'.".format([repository_name]))
	var zip_reader := ZIPReader.new()
	var zip_reader_status := zip_reader.open(zip_file_path)
	if zip_reader_status != OK:
		printerr("Fail to unzip '{0}' (Error: {1}).".format([repository_name, error_string(zip_reader_status)]))
		return null
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
	print("'{0}' unzipped.".format([repository_name]))
	
	plugin_reference = BrisklancePluginReference.find(plugin_directory_path)
	if not plugin_reference: 
		printerr("Unable to find plugin configuration for '{0}'.".format([repository_name]))
		return null
	
	for dependency_repository_name in plugin_reference.dependencies.keys():
		for mirror in BrisklanceCentralDatabase.get_singleton().head_plugin_mirrors:
			if mirror.repository_name == dependency_repository_name: continue
		
		for mirror in installed_dependent_plugin_mirrors:
			if mirror.repository_name == dependency_repository_name:
				printerr("'{0}' has already been installed by another plugin. Please install the plugin of acceptable version manually.")
				for newly_installed : BrisklancePluginMirror in installed_dependent_plugin_mirrors: 
					newly_installed.purge()
				purge()
				return null
		
		for mirror in BrisklanceCentralDatabase.get_singleton().installed_plugin_mirrors:
			if mirror.repository_name == dependency_repository_name:
				printerr("'{0}' has already been installed by another plugin. Please install the plugin of acceptable version manually.")
				for newly_installed : BrisklancePluginMirror in installed_dependent_plugin_mirrors: 
					newly_installed.purge()
				purge()
				return null
		
		var depencency := BrisklancePluginMirror.create(dependency_repository_name, plugin_reference.dependencies[dependency_repository_name])
		var dependency_plugin_reference := await depencency.retreive(p_http_request)
		if not dependency_plugin_reference:
			printerr("'{0}' cannot be installed due to '{1}'.".format([repository_name, dependency_repository_name]))
			for newly_installed : BrisklancePluginMirror in installed_dependent_plugin_mirrors: 
				newly_installed.purge()
			purge()
			return null
		
		installed_dependent_plugin_mirrors.push_back(depencency)
	
	BrisklanceCentralDatabase.get_singleton().installed_plugin_mirrors.append_array(installed_dependent_plugin_mirrors)
	BrisklanceCentralDatabase.get_singleton().save_database()
	
	return plugin_reference
