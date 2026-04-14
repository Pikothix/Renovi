class_name HouseDefinition
extends Resource

@export var display_name := "House"
@export var footprint_size := Vector2i(3, 3)
@export var north_wall_height := 2

# All house-local tiles use the top-left footprint tile as (0, 0).
@export var door_local_tile := Vector2i(1, 2)
@export var interior_spawn_local_tile := Vector2i(1, 2)
@export var interior_exit_local_tile := Vector2i(1, 3)

@export var exterior_tiles: Array[HouseTilePlacement] = []
@export var footprint_tiles: Array[Vector2i] = []

@export var floor_atlas_group: StringName = &"cabin_furniture"
@export var floor_atlas_coords := Vector2i(23, 6)
@export var inner_wall_top_atlas_group: StringName = &"cabin_furniture"
@export var inner_wall_top_atlas_coords := Vector2i(23, 4)
@export var inner_wall_bottom_atlas_group: StringName = &"cabin_furniture"
@export var inner_wall_bottom_atlas_coords := Vector2i(23, 5)
@export var interior_exit_marker_local_tile := Vector2i(1, 3)
@export var interior_exit_marker_atlas_group: StringName = &"doors_windows"
@export var interior_exit_marker_atlas_coords := Vector2i(0, 1)
@export var visible_interior_tiles: Array[Vector2i] = []

@export var border_top_left_atlas_group: StringName = &"cabin_furniture"
@export var border_top_left_atlas_coords := Vector2i(23, 0)
@export var border_top_atlas_group: StringName = &"cabin_furniture"
@export var border_top_atlas_coords := Vector2i(21, 3)
@export var border_top_right_atlas_group: StringName = &"cabin_furniture"
@export var border_top_right_atlas_coords := Vector2i(24, 0)

@export var border_left_atlas_group: StringName = &"cabin_furniture"
@export var border_left_atlas_coords := Vector2i(22, 2)
@export var border_right_atlas_group: StringName = &"cabin_furniture"
@export var border_right_atlas_coords := Vector2i(20, 2)

@export var border_bottom_left_atlas_group: StringName = &"cabin_furniture"
@export var border_bottom_left_atlas_coords := Vector2i(23, 1)
@export var border_bottom_atlas_group: StringName = &"cabin_furniture"
@export var border_bottom_atlas_coords := Vector2i(21, 1)
@export var border_bottom_right_atlas_group: StringName = &"cabin_furniture"
@export var border_bottom_right_atlas_coords := Vector2i(24, 1)


func get_floor_cells() -> Array[Vector2i]:
	if not footprint_tiles.is_empty():
		return footprint_tiles.duplicate()

	var cells: Array[Vector2i] = []
	for y in range(footprint_size.y):
		for x in range(footprint_size.x):
			cells.append(Vector2i(x, y))
	return cells


func get_inner_wall_cells() -> Array[Dictionary]:
	var cells: Array[Dictionary] = []
	var floor_tiles := get_floor_cells()
	var floor_lookup: Dictionary = {}
	for floor_tile in floor_tiles:
		floor_lookup[floor_tile] = true

	for floor_tile in floor_tiles:
		if floor_lookup.has(floor_tile + Vector2i.UP):
			continue

		cells.append({
			"cell": floor_tile + Vector2i(0, -north_wall_height),
			"atlas_group": inner_wall_top_atlas_group,
			"atlas_coords": inner_wall_top_atlas_coords
		})
		cells.append({
			"cell": floor_tile + Vector2i(0, -(north_wall_height - 1)),
			"atlas_group": inner_wall_bottom_atlas_group,
			"atlas_coords": inner_wall_bottom_atlas_coords
		})
	return cells


func get_visible_interior_rect() -> Rect2i:
	return Rect2i(Vector2i(0, -north_wall_height), Vector2i(footprint_size.x, footprint_size.y + north_wall_height))


func get_visible_interior_tiles() -> Array[Vector2i]:
	if not visible_interior_tiles.is_empty():
		return visible_interior_tiles.duplicate()

	var tiles: Array[Vector2i] = []
	var seen: Dictionary = {}

	# Visible tile coordinates can be any local shape; irregular buildings can override the list in data.
	for tile in get_interior_content_tiles():
		_append_unique_tile(tiles, seen, tile)

	for border_tile in get_border_tiles():
		_append_unique_tile(tiles, seen, border_tile["cell"])

	return tiles


func get_border_rect() -> Rect2i:
	var visible_rect := get_visible_interior_rect()
	return Rect2i(visible_rect.position - Vector2i.ONE, visible_rect.size + Vector2i(2, 2))


func get_border_tiles() -> Array[Dictionary]:
	var tiles: Array[Dictionary] = []
	var content_lookup: Dictionary = {}
	for tile in get_interior_content_tiles():
		content_lookup[tile] = true

	var border_lookup: Dictionary = {}
	var edges := [
		{"dir": Vector2i.UP, "group": border_top_atlas_group, "coords": border_top_atlas_coords},
		{"dir": Vector2i.DOWN, "group": border_bottom_atlas_group, "coords": border_bottom_atlas_coords},
		{"dir": Vector2i.LEFT, "group": border_left_atlas_group, "coords": border_left_atlas_coords},
		{"dir": Vector2i.RIGHT, "group": border_right_atlas_group, "coords": border_right_atlas_coords}
	]

	for tile in content_lookup.keys():
		for edge in edges:
			var border_cell: Vector2i = tile + edge["dir"]
			if content_lookup.has(border_cell) or border_lookup.has(border_cell):
				continue

			border_lookup[border_cell] = true
			tiles.append({
				"cell": border_cell,
				"atlas_group": edge["group"],
				"atlas_coords": edge["coords"]
			})

	for tile in content_lookup.keys():
		_append_corner_tile(tiles, border_lookup, content_lookup, tile + Vector2i(-1, -1), Vector2i.LEFT, Vector2i.UP, border_top_left_atlas_group, border_top_left_atlas_coords)
		_append_corner_tile(tiles, border_lookup, content_lookup, tile + Vector2i(1, -1), Vector2i.RIGHT, Vector2i.UP, border_top_right_atlas_group, border_top_right_atlas_coords)
		_append_corner_tile(tiles, border_lookup, content_lookup, tile + Vector2i(-1, 1), Vector2i.LEFT, Vector2i.DOWN, border_bottom_left_atlas_group, border_bottom_left_atlas_coords)
		_append_corner_tile(tiles, border_lookup, content_lookup, tile + Vector2i(1, 1), Vector2i.RIGHT, Vector2i.DOWN, border_bottom_right_atlas_group, border_bottom_right_atlas_coords)

	return tiles


func _append_unique_tile(tiles: Array[Vector2i], seen: Dictionary, cell: Vector2i) -> void:
	if seen.has(cell):
		return
	seen[cell] = true
	tiles.append(cell)


func get_interior_content_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var seen: Dictionary = {}

	for floor_tile in get_floor_cells():
		_append_unique_tile(tiles, seen, floor_tile)

	for wall_tile in get_inner_wall_cells():
		_append_unique_tile(tiles, seen, wall_tile["cell"])

	return tiles


func _append_corner_tile(tiles: Array[Dictionary], border_lookup: Dictionary, content_lookup: Dictionary, cell: Vector2i, dir_a: Vector2i, dir_b: Vector2i, atlas_group: StringName, atlas_coords: Vector2i) -> void:
	if border_lookup.has(cell) or content_lookup.has(cell):
		return
	if not content_lookup.has(cell - dir_a) or not content_lookup.has(cell - dir_b):
		return

	border_lookup[cell] = true
	tiles.append({
		"cell": cell,
		"atlas_group": atlas_group,
		"atlas_coords": atlas_coords
	})
