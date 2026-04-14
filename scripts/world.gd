extends Node2D

const HouseScene = preload("res://scenes/house_building.tscn")
const PrototypeHouseDefinition = preload("res://resources/prototype_house_3x3.tres")
const TestHouseGeneratorClass = preload("res://scripts/test_house_generator.gd")

@export_group("Test Houses")
@export var enable_generated_test_houses := true
@export_range(0.0, 1.0, 0.05) var generated_house_chance := 0.65
@export_range(0, 12, 1) var generated_house_max_structures_per_chunk := 4
@export_range(1, 4, 1) var generated_house_min_modules := 1
@export_range(1, 4, 1) var generated_house_max_modules := 4
@export var generated_house_layout_ids := PackedStringArray(["single", "duo_horizontal", "trio_horizontal", "block_2x2"])

@onready var chunk_manager = $ChunkManager
@onready var houses_root: Node2D = $Houses
@onready var interior_overlay = $InteriorOverlay

var _player: Node2D = null
var _houses: Array[HouseBuilding] = []
var _active_house: HouseBuilding = null
var _prototype_house: HouseBuilding = null
var _generated_houses_by_chunk: Dictionary = {}
var _suspend_generated_house_sync := false
var _test_house_generator := TestHouseGeneratorClass.new()


func _ready() -> void:
	chunk_manager.chunk_loaded.connect(_on_chunk_loaded)
	chunk_manager.chunk_unloaded.connect(_on_chunk_unloaded)
	_configure_test_house_generator()


func set_player(player: Node2D) -> void:
	_player = player
	_spawn_prototype_house()
	chunk_manager.set_player(player)


func regenerate_world(randomize_seed: bool = false) -> void:
	_suspend_generated_house_sync = true
	_clear_generated_houses()
	_clear_prototype_house()
	_active_house = null
	interior_overlay.set_active(false)
	chunk_manager.regenerate_world(randomize_seed)
	if _player != null:
		_spawn_prototype_house()
	_suspend_generated_house_sync = false
	_configure_test_house_generator()
	_refresh_generated_houses_for_loaded_chunks()


func get_spawn_world_position() -> Vector2:
	return chunk_manager.get_spawn_world_position()


func is_world_position_walkable(world_position: Vector2, padding: float = 0.0) -> bool:
	if _active_house != null:
		return _is_house_interior_position_walkable(world_position, padding)

	if _is_exterior_house_blocked(world_position, padding):
		return false
	return chunk_manager.is_world_position_walkable(world_position, padding)


func inspect_world_position(world_position: Vector2, player_world_position: Vector2) -> Dictionary:
	return chunk_manager.inspect_world_position(world_position, player_world_position)


func get_runtime_debug_text(player_world_position: Vector2) -> String:
	return chunk_manager.get_runtime_debug_text(player_world_position)


func get_controls_text() -> String:
	return "\n".join([
		chunk_manager.get_controls_text(),
		"E Interact Door",
		"Walk onto the interior doorway tile to exit"
	])


func get_worldgen_settings() -> WorldGenSettings:
	return chunk_manager.get_worldgen_settings()


func toggle_grid() -> void:
	chunk_manager.toggle_grid()


func toggle_chunk_borders() -> void:
	chunk_manager.toggle_chunk_borders()


func toggle_biome_overlay() -> void:
	chunk_manager.toggle_biome_overlay()


func toggle_debug_panel() -> void:
	chunk_manager.toggle_debug_panel()


func is_debug_panel_visible() -> bool:
	return chunk_manager.show_debug_panel


func try_interact(player_world_position: Vector2) -> void:
	if _active_house != null:
		return

	for house in _houses:
		if house.can_enter_from_world_position(player_world_position):
			_enter_house(house)
			return


func notify_player_world_position(player_world_position: Vector2) -> void:
	if _active_house != null and _active_house.should_exit_for_world_position(player_world_position):
		_exit_active_house()


func _spawn_prototype_house() -> void:
	if PrototypeHouseDefinition == null:
		return

	_clear_prototype_house()

	var anchor_cell := _find_house_anchor(world_to_cell(get_spawn_world_position()), PrototypeHouseDefinition)
	if anchor_cell == Vector2i(2147483647, 2147483647):
		return

	var house := HouseScene.instantiate() as HouseBuilding
	house.configure(PrototypeHouseDefinition, chunk_manager.cell_size)
	house.position = Vector2(anchor_cell * chunk_manager.cell_size)
	houses_root.add_child(house)
	_register_house(house)
	_prototype_house = house


func _clear_generated_houses() -> void:
	for chunk_coord in _generated_houses_by_chunk.keys():
		for house in _generated_houses_by_chunk[chunk_coord]:
			_unregister_house(house)
	_generated_houses_by_chunk.clear()


func _clear_prototype_house() -> void:
	if _prototype_house == null:
		return
	_unregister_house(_prototype_house)
	_prototype_house = null


func _find_house_anchor(origin_cell: Vector2i, definition: HouseDefinition) -> Vector2i:
	var preferred_anchor := origin_cell + Vector2i(4, -1)
	var invalid_cell := Vector2i(2147483647, 2147483647)

	for radius in range(0, 18):
		for y in range(preferred_anchor.y - radius, preferred_anchor.y + radius + 1):
			for x in range(preferred_anchor.x - radius, preferred_anchor.x + radius + 1):
				var candidate := Vector2i(x, y)
				if _can_place_house(candidate, origin_cell, definition):
					return candidate

	return invalid_cell


func _can_place_house(anchor_cell: Vector2i, player_spawn_cell: Vector2i, definition: HouseDefinition) -> bool:
	var footprint_rect := Rect2i(anchor_cell, definition.footprint_size)
	if footprint_rect.has_point(player_spawn_cell):
		return false

	for y in range(footprint_rect.position.y, footprint_rect.end.y):
		for x in range(footprint_rect.position.x, footprint_rect.end.x):
			var sample = chunk_manager.sample_world_cell(Vector2i(x, y))
			if not TerrainDefinitions.is_walkable(sample["terrain_id"]):
				return false

	var outside_door_cell := anchor_cell + definition.door_local_tile + Vector2i.DOWN
	var door_sample = chunk_manager.sample_world_cell(outside_door_cell)
	return TerrainDefinitions.is_walkable(door_sample["terrain_id"])


func _enter_house(house: HouseBuilding) -> void:
	if _player == null:
		return

	# Entering hides the exterior presentation on that house and reveals the masked interior view.
	_active_house = house
	_active_house.enter()
	_player.global_position = house.get_interior_spawn_world_position()
	interior_overlay.set_active(true, house.get_visible_interior_world_cells(), chunk_manager.cell_size)


func _exit_active_house() -> void:
	if _active_house == null or _player == null:
		return

	var house := _active_house
	_active_house = null
	house.exit()
	_player.global_position = house.get_outside_exit_world_position()
	interior_overlay.set_active(false)


func _is_house_interior_position_walkable(world_position: Vector2, padding: float) -> bool:
	if _active_house == null:
		return false

	var half_padding := Vector2.ONE * padding
	var sample_points := [
		world_position,
		world_position + Vector2(-half_padding.x, -half_padding.y),
		world_position + Vector2(half_padding.x, -half_padding.y),
		world_position + Vector2(-half_padding.x, half_padding.y),
		world_position + Vector2(half_padding.x, half_padding.y)
	]

	for point in sample_points:
		if not _active_house.is_interior_world_position_walkable(point):
			return false

	return true


func _is_exterior_house_blocked(world_position: Vector2, padding: float) -> bool:
	var half_padding := Vector2.ONE * padding
	var sample_points := [
		world_position,
		world_position + Vector2(-half_padding.x, -half_padding.y),
		world_position + Vector2(half_padding.x, -half_padding.y),
		world_position + Vector2(-half_padding.x, half_padding.y),
		world_position + Vector2(half_padding.x, half_padding.y)
	]

	for point in sample_points:
		for house in _houses:
			if house.blocks_world_position(point):
				return true

	return false


func world_to_cell(world_position: Vector2) -> Vector2i:
	return chunk_manager.world_to_cell(world_position)


func _on_chunk_loaded(chunk_coord: Vector2i) -> void:
	if _suspend_generated_house_sync or not enable_generated_test_houses:
		return
	if _generated_houses_by_chunk.has(chunk_coord):
		return

	# Generated stress-test buildings are owned by the same chunk lifecycle as terrain nodes.
	var blocked_world_cells := _get_reserved_world_cells_for_chunk(chunk_coord)
	var generated_records := _test_house_generator.generate_chunk_structures(
		chunk_coord,
		chunk_manager.chunk_size,
		chunk_manager.get_worldgen_settings().world_seed,
		Callable(chunk_manager, "sample_world_cell"),
		blocked_world_cells
	)

	var houses_for_chunk: Array[HouseBuilding] = []
	_generated_houses_by_chunk[chunk_coord] = houses_for_chunk
	for record in generated_records:
		var house := HouseScene.instantiate() as HouseBuilding
		house.configure(record["definition"], chunk_manager.cell_size)
		house.position = Vector2(record["anchor_cell"] * chunk_manager.cell_size)
		houses_root.add_child(house)
		_register_house(house)
		houses_for_chunk.append(house)


func _on_chunk_unloaded(chunk_coord: Vector2i) -> void:
	if not _generated_houses_by_chunk.has(chunk_coord):
		return

	for house in _generated_houses_by_chunk[chunk_coord]:
		_unregister_house(house)
	_generated_houses_by_chunk.erase(chunk_coord)


func _refresh_generated_houses_for_loaded_chunks() -> void:
	if not enable_generated_test_houses:
		return

	for chunk_coord in chunk_manager.get_loaded_chunk_coords():
		_on_chunk_loaded(chunk_coord)


func _register_house(house: HouseBuilding) -> void:
	_houses.append(house)


func _unregister_house(house: HouseBuilding) -> void:
	if not is_instance_valid(house):
		return
	_houses.erase(house)
	if _active_house == house:
		_active_house = null
		interior_overlay.set_active(false)
	house.queue_free()


func _configure_test_house_generator() -> void:
	_test_house_generator.setup(PrototypeHouseDefinition, {
		"structure_spawn_chance": generated_house_chance,
		"max_structures_per_chunk": generated_house_max_structures_per_chunk,
		"min_modules_per_structure": generated_house_min_modules,
		"max_modules_per_structure": generated_house_max_modules,
		"allowed_layout_ids": generated_house_layout_ids
	})


func _get_reserved_world_cells_for_chunk(chunk_coord: Vector2i) -> Dictionary:
	var reserved: Dictionary = {}
	if _prototype_house == null or not is_instance_valid(_prototype_house):
		return reserved

	var chunk_origin = chunk_coord * chunk_manager.chunk_size
	var chunk_rect := Rect2i(chunk_origin, Vector2i.ONE * chunk_manager.chunk_size)
	for world_cell in _prototype_house.get_occupied_world_cells():
		if chunk_rect.has_point(world_cell):
			reserved[world_cell] = true
	var prototype_door_world_cell := world_to_cell(_prototype_house.get_outside_exit_world_position())
	if chunk_rect.has_point(prototype_door_world_cell):
		reserved[prototype_door_world_cell] = true
	return reserved
