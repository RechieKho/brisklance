extends EditorExportPlugin
class_name BrisklanceManagerExcluderPlugin

const NAME := "BrisklanceManagerExcluderPlugin"
const MANAGER_DIR_PATH := "res://addons/brisklance/manager/"

static func is_path_under_directory(p_file_path: String, p_dir_path: String) -> bool:
	var abs_dir_path := ProjectSettings.globalize_path(p_dir_path).simplify_path()
	var abs_file_path := ProjectSettings.globalize_path(p_file_path).simplify_path()
	return abs_file_path.begins_with(abs_dir_path)

func _get_name() -> String:
	return NAME

func _export_file(p_path: String, p_type: String, p_features: PackedStringArray) -> void:
	if is_path_under_directory(p_path, MANAGER_DIR_PATH):
		print("Excluding {0} for export...".format([p_path]))
		skip()
