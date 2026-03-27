class_name NetworkItem extends Node3D

## Component for any placed node that should be synced over the network.
## Add as a child after placement. Self-registers in NetworkItem.all.

static var all: Array[NetworkItem] = []

var scene_path: String
var config: Dictionary

func _ready() -> void:
	all.append(self)

func _exit_tree() -> void:
	all.erase(self)

func serialize() -> Dictionary:
	var xform: Transform3D = get_parent().global_transform
	return {
		'scene': scene_path,
		'origin': xform.origin,
		'basis': xform.basis,
		'config': config,
	}
