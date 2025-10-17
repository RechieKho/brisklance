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
var plugin_mirrors : Array[BrisklancePluginMirror]

var deletion_plugin_mirror_index := -1

static func get_packed_scene() -> PackedScene:
	return preload("res://addons/brisklance/manager/interface/brisklance/brisklance.tscn") as PackedScene

func update_self_plugin_reference() -> void:
	self_plugin_reference = BrisklancePluginReference.load_self_plugin_reference()
	node_self_module_display.text = self_plugin_reference.name if self_plugin_reference else "None"

func update_addons_display() -> void:
	node_addons_display.clear()
	for plugin_reference in plugin_mirrors:
		node_addons_display.add_item(plugin_reference.repository_name)

func update_from_central_database() -> void:
	plugin_mirrors = BrisklanceCentralDatabase.get_singleton().head_plugin_mirrors
	update_addons_display()


func get_selected_plugin_reference_index() -> int:
	var selected_indices := node_addons_display.get_selected_items()
	if selected_indices.is_empty(): return -1
	var selected_index := selected_indices[0]
	return selected_index

func _ready() -> void:
	update_self_plugin_reference()
	update_from_central_database()
	
	node_show_install_trigger.pressed.connect(func() -> void:
		node_install_window.show()
		node_install_repository_name_edit.clear()
		node_install_tag_edit.clear()
		node_install_repository_name_edit.grab_focus()
	)
	
	node_show_confirm_delete_trigger.pressed.connect(func() -> void:
		var selected_index := get_selected_plugin_reference_index()
		deletion_plugin_mirror_index = selected_index
		if selected_index < 0: return
		var mirror = plugin_mirrors[selected_index]
		node_confirm_delete_window.dialog_text = "{0} '{1}'".format([delete_confirmation_text_prefix, mirror.repository_name])
		node_confirm_delete_window.show()
	)
	
	node_confirm_delete_window.confirmed.connect(func() -> void:
		if deletion_plugin_mirror_index < 0: return
		plugin_mirrors.remove_at(deletion_plugin_mirror_index)
		update_addons_display()
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
		BrisklanceCentralDatabase.get_singleton().head_plugin_mirrors.push_back(mirror)
		BrisklanceCentralDatabase.get_singleton().save_database()
		update_from_central_database()
	)
	
