@tool
extends MeshInstance3D

const size := 768.0

@export_range(4, 768, 4) var res := 32:
	set(new_resolution):
		res = new_resolution
		update_mesh()

@export var noise: FastNoiseLite:
	set(new_noise):
		noise = new_noise
		update_mesh()
		if noise and not noise.changed.is_connected(update_mesh):
			noise.changed.connect(update_mesh)

@export_range(4.0, 384.0, 4.0) var height := 64.0:
	set(new_height):
		height = new_height
		update_mesh()

@export_file("*.tscn", "*.scn") var poi_asset_paths: Array[String]:
	set(new_paths):
		poi_asset_paths = new_paths
		update_mesh()

@export_group("Grass Settings")
@export var grass_multimesh_instance: MultiMeshInstance3D:
	set(value):
		grass_multimesh_instance = value
		update_mesh()

const MIN_DISTANCE := 200.0
const MAX_ATTEMPTS := 50

func get_height(x: float, z: float) -> float:
	if not noise:
		return 0.0
	return noise.get_noise_2d(x, z) * height

func get_normal(x: float, z: float) -> Vector3:
	var epsilon := size / float(res)
	var normal := Vector3(
		(get_height(x + epsilon, z) - get_height(x - epsilon, z)) / (2.0 * epsilon),
		1.0,
		(get_height(x, z + epsilon) - get_height(x, z - epsilon)) / (2.0 * epsilon)
	)
	return normal.normalized()

func update_mesh() -> void:
	if not is_inside_tree():
		return

	var plane := PlaneMesh.new()
	plane.subdivide_depth = res
	plane.subdivide_width = res
	plane.size = Vector2(size, size)
	
	var plane_arrays := plane.get_mesh_arrays()
	var vertex_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_VERTEX]
	var normal_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_NORMAL]
	var tangent_array: PackedFloat32Array = plane_arrays[ArrayMesh.ARRAY_TANGENT]
	
	for i: int in vertex_array.size():
		var vertex := vertex_array[i]
		var normal := Vector3.UP
		var tangent := Vector3.RIGHT
		if noise:
			vertex.y = get_height(vertex.x, vertex.z)
			normal = get_normal(vertex.x, vertex.z)
			tangent = normal.cross(Vector3.UP)
		vertex_array[i] = vertex
		normal_array[i] = normal
		tangent_array[4 * i] = tangent.x
		tangent_array[4 * i + 1] = tangent.y
		tangent_array[4 * i + 2] = tangent.z
	
	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane_arrays)
	mesh = array_mesh
	
	update_collision(array_mesh)
	spawn_pois()
	generate_grass() 

func generate_grass() -> void:
	if not grass_multimesh_instance:
		return
		
	var base_mesh: Mesh = null
	var count: int = 65536 
	
	if grass_multimesh_instance.multimesh:
		base_mesh = grass_multimesh_instance.multimesh.mesh
		if grass_multimesh_instance.multimesh.instance_count > 0:
			count = grass_multimesh_instance.multimesh.instance_count

	var new_mm := MultiMesh.new()
	new_mm.transform_format = MultiMesh.TRANSFORM_3D
	new_mm.instance_count = count
	new_mm.mesh = base_mesh

	var half_size := size / 2.0
	
	var write_buffer := PackedFloat32Array()
	write_buffer.resize(count * 12)
	
	var buffer_idx := 0
	for i in range(count):
		var rx := randf_range(-half_size, half_size)
		var rz := randf_range(-half_size, half_size)
		var ry := get_height(rx, rz)
		
		var xform := Transform3D()
		
		var norm := get_normal(rx, rz)
		var right := Vector3.RIGHT if abs(norm.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
		var forward := norm.cross(right).normalized()
		var up_right := forward.cross(norm).normalized()
		
		xform.basis = Basis(up_right, norm, forward)
		xform.basis = xform.basis.scaled(Vector3(2.5, 2.5, 2.5))
		xform.origin = Vector3(rx, ry, rz)
		
		write_buffer[buffer_idx] = xform.basis.x.x
		write_buffer[buffer_idx + 1] = xform.basis.x.y
		write_buffer[buffer_idx + 2] = xform.basis.x.z
		write_buffer[buffer_idx + 3] = xform.origin.x
		
		write_buffer[buffer_idx + 4] = xform.basis.y.x
		write_buffer[buffer_idx + 5] = xform.basis.y.y
		write_buffer[buffer_idx + 6] = xform.basis.y.z
		write_buffer[buffer_idx + 7] = xform.origin.y
		
		write_buffer[buffer_idx + 8] = xform.basis.z.x
		write_buffer[buffer_idx + 9] = xform.basis.z.y
		write_buffer[buffer_idx + 10] = xform.basis.z.z
		write_buffer[buffer_idx + 11] = xform.origin.z
		
		buffer_idx += 12
		
	new_mm.buffer = write_buffer
	grass_multimesh_instance.multimesh = new_mm

func update_collision(array_mesh: ArrayMesh) -> void:
	var static_body: StaticBody3D = get_node_or_null("TerrainStaticBody")
	if not static_body:
		static_body = StaticBody3D.new()
		static_body.name = "TerrainStaticBody"
		add_child(static_body)
		if Engine.is_editor_hint() and get_tree():
			static_body.owner = get_tree().edited_scene_root

	var collision_shape: CollisionShape3D = static_body.get_node_or_null("TerrainCollisionShape")
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "TerrainCollisionShape"
		static_body.add_child(collision_shape)
		if Engine.is_editor_hint() and get_tree():
			collision_shape.owner = get_tree().edited_scene_root

	collision_shape.shape = array_mesh.create_trimesh_shape()

func spawn_pois() -> void:
	var pois_node := get_node_or_null("POIs")
	if not pois_node:
		pois_node = Node3D.new()
		pois_node.name = "POIs"
		add_child(pois_node)
		if Engine.is_editor_hint() and get_tree():
			pois_node.owner = get_tree().edited_scene_root

	var current_children := pois_node.get_children()
	for child in current_children:
		if child.is_inside_tree():
			pois_node.remove_child(child)
		child.queue_free()

	if poi_asset_paths.is_empty():
		return

	var half_size := size / 2.0
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var placed_positions: Array[Vector3] = []

	for path in poi_asset_paths:
		if path.is_empty():
			continue
			
		var loaded_scene := load(path) as PackedScene
		if not loaded_scene:
			continue

		var random_x := 0.0
		var random_z := 0.0
		var valid := false
		var attempts := 0

		while not valid:
			attempts += 1
			if attempts > MAX_ATTEMPTS:
				break

			random_x = rng.randf_range(-half_size + 50.0, half_size - 50.0)
			random_z = rng.randf_range(-half_size + 50.0, half_size - 50.0)
			
			if placed_positions.is_empty():
				valid = true
				break
			else:
				var far_enough := true
				for pos in placed_positions:
					if Vector2(random_x, random_z).distance_to(Vector2(pos.x, pos.z)) < MIN_DISTANCE:
						far_enough = false
						break

				if far_enough:
					valid = true
					break

		if not valid:
			continue
			
		var poi := loaded_scene.instantiate() as Node3D
		if not poi:
			continue

		var y := get_height(random_x, random_z)
		var spawn_pos := Vector3(random_x, y, random_z)
		placed_positions.append(spawn_pos)

		poi.add_to_group("generated_poi")
		pois_node.add_child(poi)
		if Engine.is_editor_hint() and get_tree():
			poi.owner = get_tree().edited_scene_root
		poi.position = spawn_pos

		var normal := get_normal(random_x, random_z)
		if normal.length_squared() > 0.001 and not normal.is_equal_approx(Vector3.UP):
			var right := Vector3.RIGHT if abs(normal.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
			var forward := normal.cross(right).normalized()
			var up_right := forward.cross(normal).normalized()
			poi.transform.basis = Basis(up_right, normal, forward)
