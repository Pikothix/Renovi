class_name BiomeDefinitions
extends RefCounted

const OCEAN := 0
const COAST := 1
const PLAINS := 2
const JUNGLE := 3
const WETLAND := 4
const ROCKY_UPLAND := 5


static func get_definition(biome_id: int) -> Dictionary:
	match biome_id:
		COAST:
			return {
				"id": COAST,
				"name": "Coast",
				"debug_color": Color("f1d98b"),
				"description": "Shoreline band just above sea level"
			}
		PLAINS:
			return {
				"id": PLAINS,
				"name": "Plains",
				"debug_color": Color("71c56f"),
				"description": "Moderate land with balanced climate"
			}
		JUNGLE:
			return {
				"id": JUNGLE,
				"name": "Jungle",
				"debug_color": Color("2d9a49"),
				"description": "Hot and wet biome"
			}
		WETLAND:
			return {
				"id": WETLAND,
				"name": "Wetland",
				"debug_color": Color("84a88d"),
				"description": "Low, wet terrain with soft ground"
			}
		ROCKY_UPLAND:
			return {
				"id": ROCKY_UPLAND,
				"name": "Rocky Upland",
				"debug_color": Color("79808c"),
				"description": "Higher or drier elevated terrain"
			}
		_:
			return {
				"id": OCEAN,
				"name": "Ocean",
				"debug_color": Color("3679c8"),
				"description": "Water-dominant biome"
			}


static func get_biome_name(biome_id: int) -> String:
	return str(get_definition(biome_id)["name"])


static func get_debug_color(biome_id: int) -> Color:
	return get_definition(biome_id)["debug_color"]
