extends Node3D

var chunk_scene = preload("res://Scenes/World/World_gen/Chunk.tscn")

@export var load_radius = 6
@onready var chunks = $Chunks
@onready var player = $Player

var load_thread: Thread = Thread.new()
var chunks_to_generate: Array = []  # Declare the chunks_to_generate array


func _ready():
		for i in range(-load_radius, load_radius + 1):
			for j in range(-load_radius, load_radius + 1):
				var chunk = chunk_scene.instantiate()
				chunk.set_chunk_position(Vector2(i, j))
				chunks.add_child(chunk)

		call_deferred("_thread_process")

func _thread_process(_userdata):
	print("Initializing Thread Process")
	while (true):
		if chunks_to_generate.size() > 0:
			print("Generating Chunks")
			var chunk_to_generate = chunks_to_generate.pop_front()
			chunk_to_generate.generate()
			chunk_to_generate.update()
		else:
			# Sleep briefly to avoid busy-waiting
			OS.delay_msec(10)

func get_chunk(chunk_pos):
	for c in chunks.get_children():
		if c.chunk_position == chunk_pos:
			return c
	return null

func enqueue_chunk_generation(chunk):
	chunks_to_generate.append(chunk)

func _on_Player_place_block(pos, t):
	var cx = int(floor(pos.x / Global.DIMENSION.x))
	var cz = int(floor(pos.z / Global.DIMENSION.z))

	var bx = posmod(floor(pos.x), Global.DIMENSION.x)
	var by = posmod(floor(pos.y), Global.DIMENSION.y)
	var bz = posmod(floor(pos.z), Global.DIMENSION.z)

	var c = get_chunk(Vector2(cx, cz))
	if c != null:
		c.blocks[bx][by][bz] = t
		enqueue_chunk_generation(c)

func _on_Player_break_block(pos):
	_on_Player_place_block(pos, Global.AIR)
