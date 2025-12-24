@tool
extends EditorPlugin
class_name BrisklanceEditorPlugin

const BRISKLANCE_DIRECTORY_PATH := "res://addons/brisklance"

var manager_exclusion_plugin : BrisklanceManagerExcluderPlugin
var brisklance_interface : BrisklanceInterface

func _enable_plugin() -> void:
	# Add autoloads here.
	manager_exclusion_plugin = BrisklanceManagerExcluderPlugin.new()
	add_export_plugin(manager_exclusion_plugin)
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	remove_export_plugin(manager_exclusion_plugin)
	pass


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	brisklance_interface = BrisklanceInterface.get_packed_scene().instantiate() as BrisklanceInterface
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, brisklance_interface)
	pass


func _exit_tree() -> void:
	if brisklance_interface: remove_control_from_docks(brisklance_interface)
	pass
