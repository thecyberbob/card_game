class_name Dice
extends Node3D

@export var the_dice : RigidBody3D
@export var the_camera : Camera3D
@export var follow_dice : bool = false

var initial_pos : Vector3

var dice_shooting : bool = false

var dice_face_normals

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	initial_pos = the_dice.position
	the_dice.sleeping_state_changed.connect(_on_dice_settled)
	
	var dice_mesh = $Dice/DiceMesh.mesh
	print("DM: ", dice_mesh)
	#if dice_mesh == null:
	#	print("Mesh not here yet")
	
	
	var tri_normals = get_dice_face_normals(dice_mesh)
	dice_face_normals = unique_dice_normals(tri_normals)


func shoot_dice():
	the_dice.position = initial_pos
	the_dice.apply_impulse(Vector3(randf_range(-400, 400), 0, randf_range(100, 400)))
	the_dice.apply_torque(Vector3(randf_range(200, 1200), randf_range(200, 600), randf_range(100, 400)))

func _physics_process(_delta: float) -> void:
	if follow_dice:
		the_camera.position.x = lerp(the_camera.position.x, the_dice.position.x, 0.05)
		the_camera.position.z = lerp(the_camera.position.z, the_dice.position.z, 0.05)

func _on_dice_settled():
	if the_dice.sleeping:
		print("Dice settled")
		var face = get_dice_up_face(dice_face_normals)
		print("Face index:", face)

func get_dice_normals_from_collision(convex_shape: ConvexPolygonShape3D):
	var normals := []
	
	#if shape is ConcavePolygonShape3D:
	var faces = convex_shape.shape.get_faces()
		
	# This won't work. I need to get the mesh itself. 
	# Reimport the object and grab the MESH object as well as the collision shape.
	for i in range(0, faces.size(), 3):
		var a = faces[i]
		var b = faces[i+1]
		var c = faces[i+2]

		var normal = (b - a).cross(c - a).normalized()
		normals.append(normal)

	return normals

func get_dice_face_normals(mesh: ArrayMesh) -> Array:
	var normals = []
	
	for surface in mesh.get_surface_count():
		var arrays = mesh.surface_get_arrays(surface)
		var vertices = arrays[Mesh.ARRAY_VERTEX]
		var indices = arrays[Mesh.ARRAY_INDEX]
		
		for i in range(0, indices.size(), 3):
			var a = vertices[indices[i]]
			var b = vertices[indices[i + 1]]
			var c = vertices[indices[i + 2]]
			
			var normal = (b - a).cross(c - a).normalized()
			
			normals.append(normal)
			
	return normals
	
func unique_dice_normals(triangle_normals: Array) -> Array:
	var faces = []
	var threshold : float = 0.98
	
	for n in triangle_normals:
		var found : bool = false
		
		for f in faces:
			if n.dot(f) > threshold:
				found = true
				break
		
		if not found:
			faces.append(n)
	
	return faces

func get_dice_up_face(face_normals: Array) -> int:
	var best_dot := -1.0
	var best_index := -1

	var actual_face_value : int = 0

	for i in range(face_normals.size()):
		
		var world_normal = the_dice.global_transform.basis * face_normals[i]
		var dot = world_normal.dot(Vector3.UP)

		if dot > best_dot:
			best_dot = dot
			best_index = i
	
	print("Best index: ", best_index)
	print("Number of faces: ", face_normals.size())
	
	match best_index:
		0:
			actual_face_value = 18
		1:
			actual_face_value = 2
		2:
			actual_face_value = 4
		3:
			actual_face_value = 14
		4:
			actual_face_value = 20
		5:
			actual_face_value = 12
		6:
			actual_face_value = 5
		7:
			actual_face_value = 11
		8:
			actual_face_value = 6
		9:
			actual_face_value = 8
		10:
			actual_face_value = 15
		11:
			actual_face_value = 13
		12:
			actual_face_value = 9
		13:
			actual_face_value = 16
		14:
			actual_face_value = 10
		15:
			actual_face_value = 7
		16:
			actual_face_value = 1
		17:
			actual_face_value = 19
		18:
			actual_face_value = 3
		19:
			actual_face_value = 17
	
	return actual_face_value
