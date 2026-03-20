class_name Sun extends Node3D

@export var orbit_radius: float = 2000.0
@export var orbit_speed: float = 0.01   # radians/sec — about 2.5 min per orbit
@export var mesh_radius: float = 40.0

var _angle: float = 90.0
var _light: DirectionalLight3D

func _ready() -> void:
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = mesh_radius
	sphere.height = mesh_radius * 2.0
	mi.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.82, 0.28)
	mat.emission_energy_multiplier = 8.0
	mat.albedo_color = Color(1.0, 0.9, 0.4)
	mi.material_override = mat
	add_child(mi)

	_light = DirectionalLight3D.new()
	_light.light_energy = 5
	_light.shadow_enabled = true
	_light.directional_shadow_max_distance = 1000.0
	add_child(_light)

func _process(delta: float) -> void:
	_angle += delta * orbit_speed
	global_position = Vector3(cos(_angle), sin(_angle), 0.0) * orbit_radius
	_light.look_at(Vector3.ZERO)
