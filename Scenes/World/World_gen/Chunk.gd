@tool
extends StaticBody3D

const vertices = [
	Vector3(0, 0, 0), #0
	Vector3(1, 0, 0), #1
	Vector3(0, 1, 0), #2
	Vector3(1, 1, 0), #3
	Vector3(0, 0, 1), #4
	Vector3(1, 0, 1), #5
	Vector3(0, 1, 1), #6
	Vector3(1, 1, 1)  #7
]

const TOP = [2, 3, 7, 6]
const BOTTOM = [0, 4, 5, 1]
const LEFT = [6, 4, 0, 2]
const RIGHT = [3, 1, 5, 7]
const FRONT = [7, 5, 4, 6]
const BACK = [2, 0, 1, 3]

var blocks = []

var st = SurfaceTool.new()
var mesh = null
var mesh_instance = null

var material = preload("res://Assets/Textures/Terrain/Terrain_textures_material.tres")

var chunk_position = Vector2(): set = set_chunk_position

@export var noise = FastNoiseLite.new()
@export var caveNoise = FastNoiseLite.new()

# Define additional variables for noise generation
var noise_frequency = 12
var noise_amplitude = 12  # Adjust this to control the noise amplitude
var selected_noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN  # Default noise type is Perlin

var cave_noise_frequency = 0.05
var cave_noise_amplitude = 5.0

func _ready():
	generate()
	post_process()
	generate_trees()
	update()
	
func generate():
	blocks = []
	blocks.resize(Global.DIMENSION.x)
	for i in range(Global.DIMENSION.x):
		blocks[i] = []
		blocks[i].resize(Global.DIMENSION.y + 10)  # Increase the height here
		for j in range(Global.DIMENSION.y + 10):  # Increase the height here
			blocks[i][j] = []
			blocks[i][j].resize(Global.DIMENSION.z + 10)  # Increase the depth here
			for k in range(Global.DIMENSION.z + 10):  # Increase the depth here
				var global_pos = chunk_position * \
					Vector2(Global.DIMENSION.x, Global.DIMENSION.z) + \
					Vector2(i, k)
				var noise_value_global_pos = Vector3(chunk_position.x * Global.DIMENSION.x + i, j, chunk_position.y * Global.DIMENSION.z + k)

				# Set a fixed seed for both noise and caveNoise
				noise.seed = 2
				caveNoise.seed = 1

				var noise_value = noise.get_noise_3d(global_pos.x, 0, global_pos.y) * noise_amplitude + 1 + noise_frequency
				var cave_noise_value = caveNoise.get_noise_3d(noise_value_global_pos.x, noise_value_global_pos.y, noise_value_global_pos.z) * cave_noise_amplitude

				# Use the noise_value to generate terrain
				var block = generate_block(noise_value, j, cave_noise_value)
				blocks[i][j][k] = block

func generate_trees():
	var num_trees = 10  # Adjust the number of trees as needed

	for x in range(num_trees):
		var tree_x = randi() % int(Global.DIMENSION.x)  # Convert to int
		var tree_z = randi() % int(Global.DIMENSION.z)  # Convert to int
		var ground_y = find_ground_height(tree_x, tree_z)

		if ground_y != -1:
			create_tree(tree_x, ground_y + 1, tree_z)

func generate_weeds():
	var num_weeds = 10  # Adjust the number of weeds as needed

	for x in range(num_weeds):
		var weed_x = randi() % int(Global.DIMENSION.x)  # Convert to int
		var weed_z = randi() % int(Global.DIMENSION.z)  # Convert to int
		var ground_y = find_ground_height(weed_x, weed_z)

		if ground_y != -1:
			create_weed(weed_x, ground_y + 1, weed_z)

func create_weed(x, y, z):
	var weed_height = 1  # Adjust the weed height as needed

	# Check if the target location is a suitable ground block
	if blocks[x][y - 1][z] == Global.GRASS:
		# Create the weed at the specified location
		for i in range(weed_height):
			blocks[x][y + i][z] = "res://untitled.obj" # Use the WEED block type or your desired block type


func find_ground_height(x, z):
	for y in range(Global.DIMENSION.y - 1, -1, -1):
		if blocks[x][y][z] != Global.AIR:
			return y
	return -1

func create_tree(x, y, z):
	var trunk_height = 8  # Adjust the trunk height as needed
	var leaves_radius = 3  # Adjust the leaves radius as needed

	# Check if the target location is a grass block
	if blocks[x][y - 1][z] == Global.GRASS:
		# Create the tree trunk (you can adjust dimensions)
		for i in range(trunk_height):
			blocks[x][y + i][z] = Global.WOOD  # Use the WOOD block type

		# Create leaves using a spherical shape
		for dx in range(-leaves_radius, leaves_radius + 1):
			for dy in range(-leaves_radius, leaves_radius + 1):
				for dz in range(-leaves_radius, leaves_radius + 1):
					if dx*dx + dy*dy + dz*dz <= leaves_radius*leaves_radius:
						var nx = x + dx
						var ny = y + trunk_height + dy  # Adjust the y-coordinate to start from the top of the trunk
						var nz = z + dz

						# Make sure the block is within bounds
						if nx >= 0 and nx < Global.DIMENSION.x and ny >= 0 and ny < Global.DIMENSION.y and nz >= 0 and nz < Global.DIMENSION.z:
							blocks[nx][ny][nz] = Global.LEAVES  # Use the LEAVES block type for leaves


# Define a function to generate terrain based on noise value and height
var min_starting_height = 0  # Adjust this value as needed

func generate_block(noise_value, height, cave_noise_value):
	var block = Global.AIR
	
	# Ensure the terrain starts at the minimum height
	if height < min_starting_height:
		height = min_starting_height
	
	# Adjust these thresholds as needed
	if height < noise_value - 3:
		block = Global.STONE
	elif height < noise_value - 1:
		block = Global.DIRT
	elif height <= noise_value:
		block = Global.GRASS
		
	# Adjust this condition to control cave generation
	if cave_noise_value > 0.5 and height < noise_value:  # Adjust the threshold as needed
		block = Global.AIR
	
	return block

func post_process():
	# Iterate through the blocks
	for x in range(Global.DIMENSION.x):
		for y in range(Global.DIMENSION.y):
			for z in range(Global.DIMENSION.z):
				# Check if the block is grass and there is a solid block above it
				if blocks[x][y][z] == Global.GRASS and y + 1 < Global.DIMENSION.y and Global.types[blocks[x][y + 1][z]][Global.SOLID]:
					# Change the grass block to dirt
					blocks[x][y][z] = Global.DIRT

func update():
	# Unload
	if mesh_instance != null:
		mesh_instance.queue_free()
		mesh_instance = null
	
	mesh = ArrayMesh.new()
	mesh_instance = MeshInstance3D.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for x in range(Global.DIMENSION.x):
		for y in range(Global.DIMENSION.y):
			for z in range(Global.DIMENSION.z):
				create_block(x, y, z)
	
	st.generate_normals(false)
	st.set_material(material)
	st.commit(mesh)
	mesh_instance.set_mesh(mesh)
	mesh_instance.create_trimesh_collision()
	add_child(mesh_instance)
	
	

	self.visible = true

func check_transparent(x, y, z):
	if x >= 0 and x < Global.DIMENSION.x and \
		y >= 0 and y < Global.DIMENSION.y and \
		z >= 0 and z < Global.DIMENSION.z:
			return not Global.types[blocks[x][y][z]][Global.SOLID]
	return true

func create_block(x, y, z):
	var block = blocks[x][y][z]
	if block == Global.AIR:
		return
	
	var block_info = Global.types[block]
	
	if check_transparent(x, y + 1, z):
		create_face(TOP, x, y, z, block_info[Global.TOP])
	
	if check_transparent(x, y - 1, z):
		create_face(BOTTOM, x, y, z, block_info[Global.BOTTOM])
	
	if check_transparent(x - 1, y, z):
		create_face(LEFT, x, y, z, block_info[Global.LEFT])
		
	if check_transparent(x + 1, y, z):
		create_face(RIGHT, x, y, z, block_info[Global.RIGHT])
		
	if check_transparent(x, y, z - 1):
		create_face(BACK, x, y, z, block_info[Global.BACK])
		
	if check_transparent(x, y, z + 1):
		create_face(FRONT, x, y, z, block_info[Global.FRONT])
	
func create_face(i, x, y, z, texture_atlas_offset):
	var offset = Vector3(x, y, z)
	var a = vertices[i[0]] + offset
	var b = vertices[i[1]] + offset
	var c = vertices[i[2]] + offset
	var d = vertices[i[3]] + offset
	
	var uv_offset = texture_atlas_offset / Global.TEXTURE_ATLAS_SIZE
	var height = 1.0 / Global.TEXTURE_ATLAS_SIZE.y
	var width = 1.0 / Global.TEXTURE_ATLAS_SIZE.x
	
	var uv_a = uv_offset + Vector2(0, 0)
	var uv_b = uv_offset + Vector2(0, height)
	var uv_c = uv_offset + Vector2(width, height)
	var uv_d = uv_offset + Vector2(width, 0)
	
	st.add_triangle_fan([a, b, c], [uv_a, uv_b, uv_c])
	st.add_triangle_fan([a, c, d], [uv_a, uv_c, uv_d])
	
func set_chunk_position(pos):
	chunk_position = pos
	position = Vector3(pos.x, 0, pos.y) * Global.DIMENSION
	
	self.visible = false
