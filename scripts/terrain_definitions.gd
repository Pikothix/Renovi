class_name TerrainDefinitions
extends RefCounted

const DEEP_WATER := 0
const SHALLOW_WATER := 1
const SAND := 2
const DIRT := 3
const GRASS := 4
const JUNGLE_GROUND := 5
const CLAY := 6
const STONE := 7

static func get_definition(terrain_id: int) -> Dictionary:
	match terrain_id:
		SHALLOW_WATER:
			return {
				"id": SHALLOW_WATER,
				"name": "Shallow Water",
				"walkable": false,
				"color": Color("5a9be0"),
				"tags": PackedStringArray(["aquatic", "shoreline", "wet"])
			}
		SAND:
			return {
				"id": SAND,
				"name": "Sand",
				"walkable": true,
				"color": Color("d9c16d"),
				"tags": PackedStringArray(["shoreline", "soft-ground", "dry"])
			}
		DIRT:
			return {
				"id": DIRT,
				"name": "Dirt",
				"walkable": true,
				"color": Color("8b5a3c"),
				"tags": PackedStringArray(["soft-ground"])
			}
		GRASS:
			return {
				"id": GRASS,
				"name": "Grass",
				"walkable": true,
				"color": Color("5fba61"),
				"tags": PackedStringArray(["fertile", "green"])
			}
		JUNGLE_GROUND:
			return {
				"id": JUNGLE_GROUND,
				"name": "Jungle Ground",
				"walkable": true,
				"color": Color("2f7a3d"),
				"tags": PackedStringArray(["fertile", "jungle", "wet"])
			}
		CLAY:
			return {
				"id": CLAY,
				"name": "Clay",
				"walkable": true,
				"color": Color("a8a39b"),
				"tags": PackedStringArray(["soft-ground", "wet"])
			}
		STONE:
			return {
				"id": STONE,
				"name": "Stone",
				"walkable": true,
				"color": Color("4f555d"),
				"tags": PackedStringArray(["rocky", "upland"])
			}
		_:
			return {
				"id": DEEP_WATER,
				"name": "Deep Water",
				"walkable": false,
				"color": Color("2d5ea7"),
				"tags": PackedStringArray(["aquatic", "deep", "wet"])
			}


static func get_terrain_name(terrain_id: int) -> String:
	return str(get_definition(terrain_id)["name"])


static func is_walkable(terrain_id: int) -> bool:
	return bool(get_definition(terrain_id)["walkable"])


static func get_color(terrain_id: int) -> Color:
	return get_definition(terrain_id)["color"]


static func is_water(terrain_id: int) -> bool:
	return terrain_id == DEEP_WATER or terrain_id == SHALLOW_WATER
