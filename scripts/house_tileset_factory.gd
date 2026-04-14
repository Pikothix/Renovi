class_name HouseTileSetFactory
extends RefCounted

const TILE_SIZE := Vector2i(16, 16)
const SOURCE_PATHS := {
	&"roofs": "res://assets/RVRoofs.png",
	&"walls": "res://assets/RVWalls.png",
	&"doors_windows": "res://assets/RVDoorsWindows.png",
	&"cabin_furniture": "res://assets/QuietCabinFurniture.png"
}
const SOURCE_IDS := {
	&"roofs": 0,
	&"walls": 1,
	&"doors_windows": 2,
	&"cabin_furniture": 3
}
const REQUIRED_COORDS := {
	&"roofs": [
		Vector2i(9, 10), Vector2i(10, 10), Vector2i(11, 10),
		Vector2i(9, 11), Vector2i(10, 11), Vector2i(11, 11),
		Vector2i(9, 12), Vector2i(10, 12), Vector2i(11, 12)
	],
	&"walls": [
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
		Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3)
	],
	&"doors_windows": [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(2, 5), Vector2i(2, 4)
	],
	&"cabin_furniture": [
		Vector2i(23, 6),
		Vector2i(23, 4), Vector2i(23, 5),
		Vector2i(23, 0), Vector2i(21, 3), Vector2i(24, 0),
		Vector2i(22, 2), Vector2i(20, 2),
		Vector2i(23, 1), Vector2i(21, 1), Vector2i(24, 1)
	]
}

static var _shared_tileset: TileSet


static func get_tileset() -> TileSet:
	if _shared_tileset == null:
		_shared_tileset = _build_tileset()
	return _shared_tileset


static func get_source_id(atlas_group: StringName) -> int:
	return SOURCE_IDS.get(atlas_group, -1)


static func _build_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = TILE_SIZE

	for atlas_group in SOURCE_IDS.keys():
		var source := TileSetAtlasSource.new()
		source.texture = load(SOURCE_PATHS[atlas_group])
		source.texture_region_size = TILE_SIZE
		tileset.add_source(source, SOURCE_IDS[atlas_group])
		for coords in REQUIRED_COORDS[atlas_group]:
			if not source.has_tile(coords):
				source.create_tile(coords)

	return tileset
