extends Node

# Chunk dimension
const DIMENSION = Vector3(16, 86, 16)

# Now we define a constant for the size of the texture atlas
const TEXTURE_ATLAS_SIZE = Vector2(3,2) # (3x 16) by (2x 16)

# This is to get information about each blockl type
enum {
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
	FRONT,
	BACK,
	SOLID
}

# Block types
enum {
	AIR,
	DIRT,
	GRASS,
	STONE,
	WOOD,
	LEAVES
}

# Dictionary of block types
# For each block type, it's value must be another dictionary which use enums to define certain things about the block
const types = {
	AIR:{
		SOLID:false
	},
	DIRT:{
		TOP:Vector2(2, 0), BOTTOM:Vector2(2, 0), LEFT:Vector2(2, 0),
		RIGHT:Vector2(2,0), FRONT:Vector2(2, 0), BACK:Vector2(2, 0),
		SOLID:true
	},
	GRASS:{
		TOP:Vector2(0, 0), BOTTOM:Vector2(2, 0), LEFT:Vector2(1, 0),
		RIGHT:Vector2(1,0), FRONT:Vector2(1, 0), BACK:Vector2(1, 0),
		SOLID:true
	},
	STONE:{
		TOP:Vector2(0, 1), BOTTOM:Vector2(0, 1), LEFT:Vector2(0, 1),
		RIGHT:Vector2(0, 1), FRONT:Vector2(0, 1), BACK:Vector2(0, 1),
		SOLID:true
	},
	WOOD:{
		TOP:Vector2(1, 1), BOTTOM:Vector2(1, 1), LEFT:Vector2(1, 1),
		RIGHT:Vector2(1, 1), FRONT:Vector2(1, 1), BACK:Vector2(1, 1),
		SOLID:true
	},
	LEAVES:{
		TOP:Vector2(2, 1), BOTTOM:Vector2(2, 1), LEFT:Vector2(2, 1),
		RIGHT:Vector2(2, 1), FRONT:Vector2(2, 1), BACK:Vector2(2, 1),
		SOLID:true
	}
}
