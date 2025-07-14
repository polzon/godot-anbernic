@tool
class_name AnbernicPlugin
extends EditorPlugin


var add_anbernic_platform: bool = false

static var anbernic_export := AnbernicExport.new()

static var anbernic_platform: AnbernicPlatform

var _added_export_plugin: bool = false

var _added_export_platform: bool = false


func _enter_tree() -> void:
	if anbernic_export:
		add_export_plugin(anbernic_export)
		_added_export_plugin = true
	else:
		assert(anbernic_export, "Anbernic export not properly created!")
		free()

	if anbernic_platform and add_anbernic_platform:
		_added_export_platform = true
		add_export_platform(anbernic_platform)


func _exit_tree() -> void:
	if _added_export_plugin:
		assert(anbernic_export)
		remove_export_plugin(anbernic_export)

	if _added_export_platform:
		assert(anbernic_platform)
		remove_export_platform(anbernic_platform)
		anbernic_platform.free()
