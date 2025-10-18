@tool
extends Control
class_name BrisklanceInterface

@export_group("Nodes", "node_")
@export var node_filter_edit : LineEdit
@export var node_show_install_trigger : BaseButton
@export var node_show_confirm_delete_trigger : BaseButton
@export var node_addons_display : ItemList
@export var node_self_module_display : Label
@export var node_install_window : Window
@export var node_install_repository_name_edit : LineEdit
@export var node_install_tag_edit : LineEdit
@export var node_install_trigger : BaseButton
@export var node_confirm_delete_window : ConfirmationDialog
@export var node_http_request : HTTPRequest

@export_group("Delete Confirmation", "delete_confirmation_")
@export_multiline var delete_confirmation_text_prefix := "Are you sure you want to delete: "

var self_plugin_reference : BrisklancePluginReference
var filtered_plugin_mirror : Array
var deletion_plugin_mirror : BrisklancePluginMirror

static func get_packed_scene() -> PackedScene:
	return preload("res://addons/brisklance/manager/interface/brisklance/brisklance.tscn") as PackedScene

func update_self_plugin_reference() -> void:
	self_plugin_reference = BrisklancePluginReference.load_self_plugin_reference()
	node_self_module_display.text = self_plugin_reference.name if self_plugin_reference else "None"

func update_addons_display() -> void:
	node_addons_display.clear()
	filtered_plugin_mirror.clear()
	for plugin_mirror : BrisklancePluginMirror in BrisklanceCentralDatabase.get_singleton().head_plugin_mirrors:
		if not node_filter_edit.text.is_empty():
			if not plugin_mirror.repository_name.contains(node_filter_edit.text): continue
		filtered_plugin_mirror.append(plugin_mirror)
		node_addons_display.add_item(plugin_mirror.repository_name)

func get_selected_plugin_mirror() -> BrisklancePluginMirror:
	var selected_indices := node_addons_display.get_selected_items()
	if selected_indices.is_empty(): return null
	var selected_index := selected_indices[0]
	return filtered_plugin_mirror[selected_index]

func refresh_editor() -> void:
	await get_tree().process_frame
	EditorInterface.get_resource_filesystem().scan()
	EditorInterface.get_resource_filesystem().scan_sources()

func _ready() -> void:
	update_self_plugin_reference()
	update_addons_display()
	
	node_filter_edit.text_changed.connect(func(_p_new_text) -> void:
		update_addons_display()
	)
	
	node_show_install_trigger.pressed.connect(func() -> void:
		node_install_window.show()
		node_install_repository_name_edit.clear()
		node_install_tag_edit.clear()
		node_install_repository_name_edit.grab_focus()
	)
	
	node_show_confirm_delete_trigger.pressed.connect(func() -> void:
		deletion_plugin_mirror = get_selected_plugin_mirror()
		if not deletion_plugin_mirror: return
		node_confirm_delete_window.dialog_text = "{0} '{1}'".format([delete_confirmation_text_prefix, deletion_plugin_mirror.repository_name])
		node_confirm_delete_window.show()
	)
	
	node_confirm_delete_window.confirmed.connect(func() -> void:
		if not deletion_plugin_mirror: return
		self_plugin_reference.dependencies.erase(deletion_plugin_mirror.repository_name)
		self_plugin_reference.save_configuration()
		deletion_plugin_mirror.purge()
		BrisklanceCentralDatabase.get_singleton().head_plugin_mirrors.erase(deletion_plugin_mirror)
		BrisklanceCentralDatabase.get_singleton().save_database()
		update_addons_display()
		refresh_editor()
	)
	
	node_install_window.close_requested.connect(func() -> void:
		node_install_window.hide()
		node_filter_edit.grab_focus()
	)
	
	node_install_trigger.pressed.connect(func() -> void:
		if node_install_repository_name_edit.text.is_empty(): return
		if node_install_tag_edit.text.is_empty(): return
		var mirror := BrisklancePluginMirror.create(node_install_repository_name_edit.text, node_install_tag_edit.text)
		if not await mirror.retreive(node_http_request): return
		if self_plugin_reference:
			self_plugin_reference.dependencies[node_install_repository_name_edit.text] = node_install_tag_edit.text
			self_plugin_reference.save_configuration()
		if not mirror in BrisklanceCentralDatabase.get_singleton().head_plugin_mirrors: 
			BrisklanceCentralDatabase.get_singleton().head_plugin_mirrors.push_back(mirror)
			BrisklanceCentralDatabase.get_singleton().save_database()
			update_addons_display()
		refresh_editor()
		node_install_window.hide()
	)
	
