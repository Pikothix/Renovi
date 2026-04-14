class_name TestHouseGenerator
extends RefCounted

const MODULE_TILE_SIZE := 3
const INVALID_CELL := Vector2i(2147483647, 2147483647)
const ARCHETYPE_SINGLE := &"single"
const ARCHETYPE_WIDE_RECT := &"wide_rect"
const ARCHETYPE_BLOCK_2X2 := &"block_2x2"
const DEFAULT_LAYOUTS := [
	{"id": "single", "modules": [Vector2i(0, 0)]},
	{"id": "duo_horizontal", "modules": [Vector2i(0, 0), Vector2i(1, 0)]},
	{"id": "trio_horizontal", "modules": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]},
	# Layout offsets are in connected 3x3 modules, not individual tile offsets.
	{"id": "l_corner", "modules": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]},
	{"id": "l_hook", "modules": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)]},
	{"id": "block_2x2", "modules": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]}
]

var structure_spawn_chance := 0.65
var max_structures_per_chunk := 4
var min_modules_per_structure := 1
var max_modules_per_structure := 4
var allowed_layout_ids := PackedStringArray(["single", "duo_horizontal", "trio_horizontal", "block_2x2"])

var _base_definition: HouseDefinition


func setup(base_definition: HouseDefinition, config: Dictionary) -> void:
	_base_definition = base_definition
	structure_spawn_chance = config.get("structure_spawn_chance", structure_spawn_chance)
	max_structures_per_chunk = config.get("max_structures_per_chunk", max_structures_per_chunk)
	min_modules_per_structure = config.get("min_modules_per_structure", min_modules_per_structure)
	max_modules_per_structure = config.get("max_modules_per_structure", max_modules_per_structure)
	allowed_layout_ids = config.get("allowed_layout_ids", allowed_layout_ids)


func generate_chunk_structures(chunk_coord: Vector2i, chunk_size: int, world_seed: int, terrain_sampler: Callable, blocked_world_cells: Dictionary = {}) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if _base_definition == null or max_structures_per_chunk <= 0:
		return results

	var rng := RandomNumberGenerator.new()
	# Chunk-local test generation stays deterministic from the world seed and chunk coordinates.
	rng.seed = _chunk_seed(world_seed, chunk_coord)
	var occupied_world_cells := blocked_world_cells.duplicate()
	var eligible_layouts := _eligible_layouts()

	for _i in range(max_structures_per_chunk):
		if rng.randf() > structure_spawn_chance or eligible_layouts.is_empty():
			continue

		var layout: Dictionary = eligible_layouts[rng.randi_range(0, eligible_layouts.size() - 1)]
		var definition := _build_definition(layout["modules"])
		var anchor_local := _find_anchor_in_chunk(rng, definition, chunk_size, chunk_coord, terrain_sampler, occupied_world_cells)
		if anchor_local == INVALID_CELL:
			continue

		var anchor_world_cell := chunk_coord * chunk_size + anchor_local
		_mark_occupied(occupied_world_cells, definition, anchor_world_cell)
		results.append({
			"anchor_cell": anchor_world_cell,
			"definition": definition
		})

	return results


func _eligible_layouts() -> Array[Dictionary]:
	var layouts: Array[Dictionary] = []
	for layout in DEFAULT_LAYOUTS:
		var module_count: int = layout["modules"].size()
		if module_count < min_modules_per_structure or module_count > max_modules_per_structure:
			continue
		if not allowed_layout_ids.has(layout["id"]):
			continue
		if not _is_supported_shell_layout(layout["modules"]):
			continue
		layouts.append(layout)
	return layouts


func _build_definition(module_offsets: Array) -> HouseDefinition:
	var normalized_modules := _normalize_modules(module_offsets)
	var module_bounds := _module_bounds(normalized_modules)
	var definition := HouseDefinition.new()
	definition.display_name = "Generated Test House"
	definition.north_wall_height = _base_definition.north_wall_height
	definition.floor_atlas_group = _base_definition.floor_atlas_group
	definition.floor_atlas_coords = _base_definition.floor_atlas_coords
	definition.inner_wall_top_atlas_group = _base_definition.inner_wall_top_atlas_group
	definition.inner_wall_top_atlas_coords = _base_definition.inner_wall_top_atlas_coords
	definition.inner_wall_bottom_atlas_group = _base_definition.inner_wall_bottom_atlas_group
	definition.inner_wall_bottom_atlas_coords = _base_definition.inner_wall_bottom_atlas_coords
	definition.interior_exit_marker_atlas_group = _base_definition.interior_exit_marker_atlas_group
	definition.interior_exit_marker_atlas_coords = _base_definition.interior_exit_marker_atlas_coords
	definition.border_top_left_atlas_group = _base_definition.border_top_left_atlas_group
	definition.border_top_left_atlas_coords = _base_definition.border_top_left_atlas_coords
	definition.border_top_atlas_group = _base_definition.border_top_atlas_group
	definition.border_top_atlas_coords = _base_definition.border_top_atlas_coords
	definition.border_top_right_atlas_group = _base_definition.border_top_right_atlas_group
	definition.border_top_right_atlas_coords = _base_definition.border_top_right_atlas_coords
	definition.border_left_atlas_group = _base_definition.border_left_atlas_group
	definition.border_left_atlas_coords = _base_definition.border_left_atlas_coords
	definition.border_right_atlas_group = _base_definition.border_right_atlas_group
	definition.border_right_atlas_coords = _base_definition.border_right_atlas_coords
	definition.border_bottom_left_atlas_group = _base_definition.border_bottom_left_atlas_group
	definition.border_bottom_left_atlas_coords = _base_definition.border_bottom_left_atlas_coords
	definition.border_bottom_atlas_group = _base_definition.border_bottom_atlas_group
	definition.border_bottom_atlas_coords = _base_definition.border_bottom_atlas_coords
	definition.border_bottom_right_atlas_group = _base_definition.border_bottom_right_atlas_group
	definition.border_bottom_right_atlas_coords = _base_definition.border_bottom_right_atlas_coords

	var footprint_tiles: Array[Vector2i] = []
	var footprint_lookup: Dictionary = {}
	for module_offset in normalized_modules:
		for y in range(MODULE_TILE_SIZE):
			for x in range(MODULE_TILE_SIZE):
				var tile := module_offset * MODULE_TILE_SIZE + Vector2i(x, y)
				if footprint_lookup.has(tile):
					continue
				footprint_lookup[tile] = true
				footprint_tiles.append(tile)

	definition.footprint_tiles = footprint_tiles
	definition.footprint_size = _tile_bounds(footprint_tiles).size

	var archetype := _classify_archetype(module_bounds)
	definition.door_local_tile = _build_front_door_local_tile(module_bounds)
	definition.interior_spawn_local_tile = definition.door_local_tile
	definition.interior_exit_local_tile = definition.door_local_tile + Vector2i.DOWN
	definition.interior_exit_marker_local_tile = definition.interior_exit_local_tile
	definition.exterior_tiles = _build_archetype_exterior_tiles(archetype, module_bounds, definition.door_local_tile)

	# Freeze the combined visible shape so the blackout mask can use one tile list per composite building.
	definition.visible_interior_tiles = definition.get_visible_interior_tiles()
	return definition


func _build_archetype_exterior_tiles(archetype: StringName, module_bounds: Rect2i, door_local_tile: Vector2i) -> Array[HouseTilePlacement]:
	# Generated composites use explicit shell blueprints per supported archetype so they keep the original 3x3 visual grammar.
	match archetype:
		ARCHETYPE_SINGLE:
			return _clone_base_exterior_tiles()
		ARCHETYPE_WIDE_RECT:
			return _build_wide_rect_exterior_tiles(module_bounds, door_local_tile)
		ARCHETYPE_BLOCK_2X2:
			return _build_block_2x2_exterior_tiles(module_bounds, door_local_tile)
		_:
			return _build_wide_rect_exterior_tiles(module_bounds, door_local_tile)


func _clone_base_exterior_tiles() -> Array[HouseTilePlacement]:
	var placements: Array[HouseTilePlacement] = []
	for base_placement in _base_definition.exterior_tiles:
		placements.append(_make_placement(base_placement.layer, base_placement.cell, base_placement.atlas_group, base_placement.atlas_coords))
	return placements


func _build_wide_rect_exterior_tiles(module_bounds: Rect2i, door_local_tile: Vector2i) -> Array[HouseTilePlacement]:
	var placements: Array[HouseTilePlacement] = []
	var width_tiles := module_bounds.size.x * MODULE_TILE_SIZE

	# The missing middle roof atlas row is now supported, so explicit generated archetypes can use authored top/middle/bottom roof stacks.
	for x in range(width_tiles):
		placements.append(_make_placement(&"roof", Vector2i(x, -1), &"roofs", _roof_top_coords(x, width_tiles)))
		placements.append(_make_placement(&"roof", Vector2i(x, 0), &"roofs", _roof_middle_coords(x, width_tiles)))
		placements.append(_make_placement(&"roof", Vector2i(x, 1), &"roofs", _roof_bottom_coords(x, width_tiles)))
		placements.append(_make_placement(&"wall", Vector2i(x, 1), &"walls", _wall_upper_coords(x, width_tiles)))
		placements.append(_make_placement(&"wall", Vector2i(x, 2), &"walls", _wall_lower_coords(x, width_tiles)))

	for window_cell in _get_facade_window_cells(width_tiles, door_local_tile.x):
		placements.append(_make_placement(&"detail", Vector2i(window_cell, 2), &"doors_windows", _window_coords(window_cell, door_local_tile.x)))

	placements.append(_make_placement(&"detail", Vector2i(door_local_tile.x, 2), &"doors_windows", Vector2i(0, 0)))
	return placements


func _build_block_2x2_exterior_tiles(module_bounds: Rect2i, door_local_tile: Vector2i) -> Array[HouseTilePlacement]:
	var placements: Array[HouseTilePlacement] = []
	var width_tiles := module_bounds.size.x * MODULE_TILE_SIZE
	var roof_rows := [
		{"y": -1, "kind": &"top"},
		{"y": 0, "kind": &"middle"},
		{"y": 1, "kind": &"bottom"},
		{"y": 2, "kind": &"top"},
		{"y": 3, "kind": &"middle"},
		{"y": 4, "kind": &"bottom"}
	]

	for roof_row in roof_rows:
		for x in range(width_tiles):
			placements.append(_make_placement(&"roof", Vector2i(x, roof_row["y"]), &"roofs", _roof_row_coords(roof_row["kind"], x, width_tiles)))

	for x in range(width_tiles):
		placements.append(_make_placement(&"wall", Vector2i(x, 4), &"walls", _wall_upper_coords(x, width_tiles)))
		placements.append(_make_placement(&"wall", Vector2i(x, 5), &"walls", _wall_lower_coords(x, width_tiles)))

	for window_cell in _get_facade_window_cells(width_tiles, door_local_tile.x):
		placements.append(_make_placement(&"detail", Vector2i(window_cell, 5), &"doors_windows", _window_coords(window_cell, door_local_tile.x)))

	placements.append(_make_placement(&"detail", Vector2i(door_local_tile.x, 5), &"doors_windows", Vector2i(0, 0)))
	return placements


func _build_front_door_local_tile(module_bounds: Rect2i) -> Vector2i:
	var width_tiles := module_bounds.size.x * MODULE_TILE_SIZE
	var depth_tiles := module_bounds.size.y * MODULE_TILE_SIZE
	# The front facade spans the whole south edge of the supported rectangular shell.
	return Vector2i(int(floor((width_tiles - 1) / 2.0)), depth_tiles - 1)


func _find_anchor_in_chunk(rng: RandomNumberGenerator, definition: HouseDefinition, chunk_size: int, chunk_coord: Vector2i, terrain_sampler: Callable, occupied_world_cells: Dictionary) -> Vector2i:
	var visible_bounds := _tile_bounds(definition.get_visible_interior_tiles())
	var min_anchor_x := -visible_bounds.position.x
	var max_anchor_x := chunk_size - visible_bounds.end.x
	var min_anchor_y := -visible_bounds.position.y
	var max_anchor_y := chunk_size - visible_bounds.end.y

	if min_anchor_x > max_anchor_x or min_anchor_y > max_anchor_y:
		return INVALID_CELL

	for _attempt in range(12):
		var anchor_local := Vector2i(
			rng.randi_range(min_anchor_x, max_anchor_x),
			rng.randi_range(min_anchor_y, max_anchor_y)
		)
		var anchor_world_cell := chunk_coord * chunk_size + anchor_local
		if _is_valid_placement(definition, anchor_world_cell, terrain_sampler, occupied_world_cells):
			return anchor_local

	return INVALID_CELL


func _is_valid_placement(definition: HouseDefinition, anchor_world_cell: Vector2i, terrain_sampler: Callable, occupied_world_cells: Dictionary) -> bool:
	for footprint_tile in definition.get_floor_cells():
		var world_cell := anchor_world_cell + footprint_tile
		if occupied_world_cells.has(world_cell):
			return false
		var sample: Dictionary = terrain_sampler.call(world_cell)
		if not TerrainDefinitions.is_walkable(sample["terrain_id"]):
			return false

	var exterior_door_cell := anchor_world_cell + definition.door_local_tile + Vector2i.DOWN
	if occupied_world_cells.has(exterior_door_cell):
		return false
	var door_sample: Dictionary = terrain_sampler.call(exterior_door_cell)
	if not TerrainDefinitions.is_walkable(door_sample["terrain_id"]):
		return false

	for visible_tile in definition.get_visible_interior_tiles():
		if occupied_world_cells.has(anchor_world_cell + visible_tile):
			return false

	return true


func _mark_occupied(occupied_world_cells: Dictionary, definition: HouseDefinition, anchor_world_cell: Vector2i) -> void:
	for footprint_tile in definition.get_floor_cells():
		occupied_world_cells[anchor_world_cell + footprint_tile] = true

	for visible_tile in definition.get_visible_interior_tiles():
		occupied_world_cells[anchor_world_cell + visible_tile] = true

	occupied_world_cells[anchor_world_cell + definition.door_local_tile + Vector2i.DOWN] = true


func _normalize_modules(module_offsets: Array) -> Array[Vector2i]:
	var min_offset := Vector2i(2147483647, 2147483647)
	for offset in module_offsets:
		min_offset.x = mini(min_offset.x, offset.x)
		min_offset.y = mini(min_offset.y, offset.y)

	var normalized: Array[Vector2i] = []
	for offset in module_offsets:
		normalized.append(offset - min_offset)
	return normalized


func _is_supported_shell_layout(module_offsets: Array) -> bool:
	var normalized_modules := _normalize_modules(module_offsets)
	if not _is_rectangular_module_set(normalized_modules):
		return false
	return _classify_archetype(_module_bounds(normalized_modules)) != StringName()


func _classify_archetype(module_bounds: Rect2i) -> StringName:
	# Keep generated rendering limited to cleanly authored shell archetypes; add new blueprint builders here as more shapes are supported.
	if module_bounds.size == Vector2i(1, 1):
		return ARCHETYPE_SINGLE
	if module_bounds.size.y == 1 and module_bounds.size.x >= 2 and module_bounds.size.x <= 3:
		return ARCHETYPE_WIDE_RECT
	if module_bounds.size == Vector2i(2, 2):
		return ARCHETYPE_BLOCK_2X2
	return StringName()

func _is_rectangular_module_set(module_offsets: Array) -> bool:
	var module_bounds := _module_bounds(module_offsets)
	var expected_count := module_bounds.size.x * module_bounds.size.y
	if module_offsets.size() != expected_count:
		return false

	var lookup: Dictionary = {}
	for offset in module_offsets:
		lookup[offset] = true

	for y in range(module_bounds.size.y):
		for x in range(module_bounds.size.x):
			if not lookup.has(Vector2i(x, y)):
				return false

	return true


func _module_bounds(module_offsets: Array) -> Rect2i:
	return _tile_bounds(module_offsets)


func _tile_bounds(cells: Array[Vector2i]) -> Rect2i:
	var min_cell = cells.front()
	var max_cell = cells.front()

	for cell in cells:
		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)

	return Rect2i(min_cell, max_cell - min_cell + Vector2i.ONE)


func _chunk_seed(world_seed: int, chunk_coord: Vector2i) -> int:
	return int(world_seed + chunk_coord.x * 92821 + chunk_coord.y * 68917 + 41413)


func _make_placement(layer: StringName, cell: Vector2i, atlas_group: StringName, atlas_coords: Vector2i) -> HouseTilePlacement:
	var placement := HouseTilePlacement.new()
	placement.layer = layer
	placement.cell = cell
	placement.atlas_group = atlas_group
	placement.atlas_coords = atlas_coords
	return placement


func _roof_top_coords(x: int, width_tiles: int) -> Vector2i:
	if x == 0:
		return Vector2i(9, 10)
	if x == width_tiles - 1:
		return Vector2i(11, 10)
	return Vector2i(10, 10)


func _roof_body_coords(x: int, width_tiles: int) -> Vector2i:
	if x == 0:
		return Vector2i(9, 12)
	if x == width_tiles - 1:
		return Vector2i(11, 12)
	return Vector2i(10, 12)


func _roof_middle_coords(x: int, width_tiles: int) -> Vector2i:
	if x == 0:
		return Vector2i(9, 11)
	if x == width_tiles - 1:
		return Vector2i(11, 11)
	return Vector2i(10, 11)


func _roof_bottom_coords(x: int, width_tiles: int) -> Vector2i:
	return _roof_body_coords(x, width_tiles)


func _roof_row_coords(kind: StringName, x: int, width_tiles: int) -> Vector2i:
	if kind == &"top":
		return _roof_top_coords(x, width_tiles)
	if kind == &"middle":
		return _roof_middle_coords(x, width_tiles)
	return _roof_bottom_coords(x, width_tiles)


func _wall_upper_coords(x: int, width_tiles: int) -> Vector2i:
	if x == 0:
		return Vector2i(0, 2)
	if x == width_tiles - 1:
		return Vector2i(2, 2)
	return Vector2i(1, 2)


func _wall_lower_coords(x: int, width_tiles: int) -> Vector2i:
	if x == 0:
		return Vector2i(0, 3)
	if x == width_tiles - 1:
		return Vector2i(2, 3)
	return Vector2i(1, 3)


func _get_facade_window_cells(width_tiles: int, door_x: int) -> Array[int]:
	var cells: Array[int] = []
	if width_tiles <= 1:
		return cells

	var left_window := 0 if width_tiles <= 3 else 1
	var right_window := width_tiles - 1 if width_tiles <= 3 else width_tiles - 2

	if left_window != door_x:
		cells.append(left_window)
	if right_window != door_x and right_window != left_window:
		cells.append(right_window)

	return cells


func _window_coords(window_x: int, door_x: int) -> Vector2i:
	if window_x < door_x:
		return Vector2i(2, 4)
	return Vector2i(2, 5)
