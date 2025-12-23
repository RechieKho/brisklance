@tool
extends Control
class_name BrisklanceInterface

@export_group("Nodes", "node_")
@export var node_filter_edit : LineEdit
@export var node_show_install_trigger : BaseButton
@export var node_show_confirm_delete_trigger : BaseButton
@export var node_addons_display : ItemList
@export var node_github_setting_configure_trigger : BaseButton
@export var node_install_window : Window
@export var node_install_repository_name_edit : LineEdit
@export var node_install_tag_edit : LineEdit
@export var node_install_trigger : BaseButton
@export var node_configure_github_setting_window : Window
@export var node_github_setting_api_key_edit : LineEdit
@export var node_github_setting_save_trigger : BaseButton
@export var node_confirm_delete_window : ConfirmationDialog
@export var node_http_request : HTTPRequest

@export_group("Delete Confirmation", "delete_confirmation_")
@export_multiline var delete_confirmation_text_prefix := "Are you sure you want to delete: "

var filtered_plugin_mirror : Array
var deletion_plugin_mirror : BrisklancePluginMirror

static func get_packed_scene() -> PackedScene:
	return preload("res://addons/brisklance/manager/interface/brisklance/brisklance.tscn") as PackedScene

func get_selected_plugin_mirror() -> BrisklancePluginMirror:
	var selected_indices := node_addons_display.get_selected_items()
	if selected_indices.is_empty(): return null
	var selected_index := selected_indices[0]
	return filtered_plugin_mirror[selected_index]

func update_addons_display() -> void:
	node_addons_display.clear()
	filtered_plugin_mirror.clear()
	for plugin_mirror : BrisklancePluginMirror in BrisklanceCentralDatabase.get_singleton().plugin_mirrors:
		if not node_filter_edit.text.is_empty():
			if not plugin_mirror.repository_name.contains(node_filter_edit.text): continue
		filtered_plugin_mirror.append(plugin_mirror)
		node_addons_display.add_item("{0} ({1})".format([plugin_mirror.repository_name, plugin_mirror.repository_tag]))

func update_self_plugin_reference() -> void:
	var self_plugin_reference := BrisklancePluginReference.load_self_plugin_reference()
	if not self_plugin_reference: return
	self_plugin_reference.dependency_dictionary = BrisklanceCentralDatabase.get_singleton().generate_dependency_dictionary()
	self_plugin_reference.save_configuration()

func commit() -> void:
	await BrisklanceCentralDatabase.get_singleton().install(node_http_request)
	update_self_plugin_reference()
	BrisklanceCentralDatabase.get_singleton().save_database()
	BrisklanceLocalDevelopmentStore.get_singleton().save_store()
	update_addons_display()
	if not EditorInterface.get_resource_filesystem().is_scanning(): 
		EditorInterface.get_resource_filesystem().scan()

func _ready() -> void:
	commit()
	
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
		deletion_plugin_mirror.purge_all()
		BrisklanceCentralDatabase.get_singleton().plugin_mirrors.erase(deletion_plugin_mirror)
		commit()
	)
	
	node_configure_github_setting_window.close_requested.connect(func() -> void:
		node_configure_github_setting_window.hide()
		node_filter_edit.grab_focus()
	)
	
	node_github_setting_configure_trigger.pressed.connect(func() -> void:
		node_github_setting_api_key_edit.text = BrisklanceLocalDevelopmentStore.get_singleton().github_api_key
		node_configure_github_setting_window.show()
		node_github_setting_api_key_edit.grab_focus()
	)
	
	node_install_window.close_requested.connect(func() -> void:
		node_install_window.hide()
		node_filter_edit.grab_focus()
	)
	
	node_install_trigger.pressed.connect(func() -> void:
		if node_install_repository_name_edit.text.is_empty(): return
		if node_install_tag_edit.text.is_empty(): return
		var mirror := BrisklancePluginMirror.create(node_install_repository_name_edit.text, node_install_tag_edit.text)
		if mirror.repository_name in BrisklanceCentralDatabase.get_singleton().get_plugin_mirror_repository_names(): return
		if not await mirror.retreive_self(node_http_request): return
		BrisklanceCentralDatabase.get_singleton().plugin_mirrors.push_back(mirror)
		commit()
		node_install_window.hide()
	)
	
	node_github_setting_save_trigger.pressed.connect(func() -> void:
		BrisklanceLocalDevelopmentStore.get_singleton().github_api_key = node_github_setting_api_key_edit.text
		commit()
		node_configure_github_setting_window.hide()
	)
