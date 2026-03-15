extends RigidBody3D

var previewmesh = preload("res://asset/preview.tres")
var projectile = preload("res://scenes/projectile.tscn")
var SPEED = 100

func _ready() -> void:
	$Timer.timeout.connect(self._on_Timer_timeout)

	if get_parent().get_name() == "Player":
		toggle_visible()
		enable_preview()

func _on_Timer_timeout():
	item_action()

func toggle_visible():
	visible = not visible

func item_action():
	var rock = projectile.instantiate()
	add_child(rock, true)
	rock.global_transform = $Spawner.global_transform
	var outwards = rock.global_transform.basis.z + rock.global_transform.basis.y
	rock.apply_central_impulse(outwards*SPEED)

func enable_preview():
	# previewmesh is a transparent green mesh to replace the tower
	# we also need to disable collision
	#
	$Timer.stop()
	$Base.set_surface_override_material(0, previewmesh)
	$Base/Spout.set_surface_override_material(0, previewmesh)
	$BaseCollider.set_disabled(true)
	$SpoutCollider.set_disabled(true)








func make_triangle():
	var st = SurfaceTool.new()

	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Prepare attributes for add_vertex.
	st.add_normal(Vector3(0, 0, 1))
	st.add_uv(Vector2(0, 0))
	# Call last for each vertex, adds the above attributes.
	st.add_vertex(Vector3(-1, -1, 0))

	st.add_normal(Vector3(0, 0, 1))
	st.add_uv(Vector2(0, 1))
	st.add_vertex(Vector3(-1, 10, 0))

	st.add_normal(Vector3(0, 0, 1))
	st.add_uv(Vector2(1, 1))
	st.add_vertex(Vector3(1, 1, 0))

	# Create indices, indices are optional.
	st.index()

	# Commit to a mesh.
	return st.commit()
	# then do this on a mesh instance 	rock.get_child(1).create_trimesh_collision()
