class_name Atom extends Node3D

@export var linear: Vector3 = Vector3.ZERO  # fixed directional force
@export var radial: float = 0.0             # positive = push, negative = pull (relative to field center)
@export var focal: float = 0.0             # positive = pull toward atom, negative = push away from atom
@export var orient: bool = false            # if true, drives field area gravity for player orientation instead of apply_central_force
@export var light: float = 0.0:            # emission energy; 0 = no glow
	set(value):
		light = value
		if is_node_ready() and value > 0.0:
			_setup_light()
@export var light_color: Color = Color.WHITE
@export var light_range: float = 0.0       # OmniLight3D range; 0 = skip light node
var is_held := false
var _light_ready := false
var _inv: InventoryItem

@onready var _area: Area3D = $area_3d

func _ready() -> void:
	_area.set_meta("field_area", true)
	if light > 0.0:
		_setup_light()
	_inv = InventoryItem.new()
	_inv.name = "InventoryItem"
	add_child(_inv)
	_inv.preview_mode.connect(_on_preview_mode)

func _on_preview_mode() -> void:
	is_held = true
	hide()

func _setup_light() -> void:
	if _light_ready:
		return
	_light_ready = true
	var mi: MeshInstance3D = $mesh_instance_3d
	mi.scale = Vector3.ONE * (1.0 + light * 0.5)
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = light_color
	mat.emission_energy_multiplier = light * 2.0
	mat.albedo_color = light_color
	mi.material_override = mat
	if light_range > 0.0:
		var omni := OmniLight3D.new()
		omni.light_color = light_color
		omni.light_energy = light
		omni.omni_range = light_range
		add_child(omni)
