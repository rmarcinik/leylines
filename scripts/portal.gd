extends Node3D

@onready var _timer: Timer = $Portal_timer # Timer node, wait time: 5s, one shot: true
@onready var _enter: Node3D = $Enter
@onready var _exit: Node3D = $Exit
@onready var _enterarea: Area3D = $Enter/Area3D
@onready var _exitarea: Area3D = $Exit/Area3D
@onready var _entercam: Camera3D = $Enter/EnterView/EnterCam
@onready var _exitcam: Camera3D = $Exit/ExitView/ExitCam

func _ready():
	_enterarea.body_entered.connect(_on_body_entered.bind(_exitarea))
	_exitarea.body_entered.connect(_on_body_entered.bind(_enterarea))
	_set_viewport_mat($Enter/MeshInstance3D, $Exit/ExitView)
	_set_viewport_mat($Exit/MeshInstance3D, $Enter/EnterView)

func _on_body_entered(body: PhysicsBody3D, exit: Node3D):
	if body is Player and _timer.is_stopped():
		_timer.start()
		body.global_position = exit.global_position

func _process(_delta: float) -> void:
	portal_mover()


func portal_mover():
	var viewport = get_viewport()
	var camera = viewport.get_camera_3d()
	var view_pos = camera.global_position

	# Make portal entrances look at viewport camera
	_enter.look_at(view_pos)
	_exit.look_at(view_pos)

	# Make cameras face opposite direction by rotating 180° around Y axis
	_entercam.basis = _exit.basis.rotated(Vector3.UP, PI)
	_exitcam.basis = _enter.basis.rotated(Vector3.UP, PI)

# https://old.reddit.com/r/godot/comments/13d93o1/godot_4_viewport_texture_error/
# avoids false error if the viewport texture is set in code
func _set_viewport_mat(_display_mesh: MeshInstance3D, _sub_viewport: SubViewport, _surface_id: int = 0):
	var _mat: StandardMaterial3D = StandardMaterial3D.new()
	var viewport_texture = _sub_viewport.get_texture()
	_mat.albedo_texture = viewport_texture
	_mat.emission_enabled = true
	_mat.emission_texture = viewport_texture
	_mat.emission_energy_multiplier = 1.0  # Adjust this value to control brightness
	_display_mesh.set_surface_override_material(_surface_id, _mat)
