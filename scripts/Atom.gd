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
var _fields: Array[Field] = []

@onready var _area: Area3D = $area_3d

func _ready() -> void:
	if light > 0.0:
		_setup_light()
	if get_parent() is Player:
		is_held = true
		visible = false
	else:
		_area.area_entered.connect(_on_area_entered)
		_area.area_exited.connect(_on_area_exited)

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

func _on_area_entered(area: Area3D) -> void:
	var field := area.get_parent() as Field
	if field:
		_fields.append(field)
		_resync_fields()
		return
	var player := area.get_parent().get_parent() as Player
	if player and not player.item_action.is_connected(queue_free):
		player.item_action.connect(queue_free)

func _on_area_exited(area: Area3D) -> void:
	var field := area.get_parent() as Field
	if field:
		field.remove_atom(self)
		_fields.erase(field)
		_resync_fields()
		return
	var player := area.get_parent().get_parent() as Player
	if player and player.item_action.is_connected(queue_free):
		player.item_action.disconnect(queue_free)

func _resync_fields() -> void:
	if _fields.is_empty():
		return
	var min_r := _fields[0].get_radius()
	for f in _fields:
		min_r = min(min_r, f.get_radius())
	for f in _fields:
		f.add_atom(self, min_r / f.get_radius())
