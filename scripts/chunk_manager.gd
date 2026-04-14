extends Node2D

signal chunk_loaded(chunk_coord: Vector2i)
signal chunk_unloaded(chunk_coord: Vector2i)

const ChunkDataClass = preload("res://scripts/chunk_data.gd")
const ChunkScene = preload("res://scenes/chunk.tscn")
const WorldGeneratorClass = preload("res://scripts/world_generator.gd")
const WorldGenSettingsClass = preload("res://scripts/worldgen_settings.gd")

@export_group("Chunk Settings")
@export_range(8, 64, 1) var chunk_size: int = 16
@export_range(8, 32, 1) var cell_size: int = 16
@export_range(1, 6, 1) var load_radius: int = 2
@export_range(1, 8, 1) var unload_radius: int = 3

@export_group("World Generation")
@export var worldgen_settings: WorldGenSettings = WorldGenSettingsClass.new()

@export_group("Debug")
@export var show_grid := false
@export var show_chunk_borders := true
@export var show_biome_overlay := false
@export var show_debug_panel := true

var _player: Node2D = null
var _loaded_chunks: Dictionary = {}
var _generator := WorldGeneratorClass.new()
var _last_player_chunk := Vector2i(2147483647, 2147483647)


func _ready() -> void:
	_configure_generator()


func _process(_delta: float) -> void:
	if _player == null:
		return

	var player_chunk := world_to_chunk(_player.global_position)
	if player_chunk != _last_player_chunk or _loaded_chunks.is_empty():
		_update_loaded_chunks(player_chunk)


func set_player(player: Node2D) -> void:
	_player = player
	_update_loaded_chunks(world_to_chunk(player.global_position))


func regenerate_world(randomize_seed: bool = false) -> void:
	if randomize_seed:
		worldgen_settings.world_seed = int(Time.get_ticks_msec())
	_configure_generator()
	_clear_loaded_chunks()
	_last_player_chunk = Vector2i(2147483647, 2147483647)
	if _player != null:
		_update_loaded_chunks(world_to_chunk(_player.global_position))


func toggle_grid() -> void:
	show_grid = not show_grid
	_refresh_chunk_debug_options()


func toggle_chunk_borders() -> void:
	show_chunk_borders = not show_chunk_borders
	_refresh_chunk_debug_options()


func toggle_biome_overlay() -> void:
	show_biome_overlay = not show_biome_overlay
	_refresh_chunk_debug_options()


func toggle_debug_panel() -> void:
	show_debug_panel = not show_debug_panel


func is_world_position_walkable(world_position: Vector2, padding: float = 0.0) -> bool:
	var half_padding := Vector2.ONE * padding
	var sample_points := [
		world_position,
		world_position + Vector2(-half_padding.x, -half_padding.y),
		world_position + Vector2(half_padding.x, -half_padding.y),
		world_position + Vector2(-half_padding.x, half_padding.y),
		world_position + Vector2(half_padding.x, half_padding.y)
	]

	for point in sample_points:
		var cell := world_to_cell(point)
		var sample := sample_world_cell(cell)
		if not TerrainDefinitions.is_walkable(sample["terrain_id"]):
			return false

	return true


func inspect_world_position(world_position: Vector2, player_world_position: Vector2) -> Dictionary:
	var world_cell := world_to_cell(world_position)
	var chunk_coord := cell_to_chunk(world_cell)
	var local_cell := world_cell - chunk_coord * chunk_size
	var sample := sample_world_cell(world_cell)

	return {
		"world_cell": world_cell,
		"chunk_coord": chunk_coord,
		"local_cell": local_cell,
		"landmass": sample["landmass"],
		"moisture": sample["moisture"],
		"temperature": sample["temperature"],
		"uplift": sample["uplift"],
		"biome_name": BiomeDefinitions.get_biome_name(sample["biome_id"]),
		"biome_id": sample["biome_id"],
		"terrain_name": TerrainDefinitions.get_terrain_name(sample["terrain_id"]),
		"terrain_id": sample["terrain_id"],
		"walkable": TerrainDefinitions.is_walkable(sample["terrain_id"]),
		"loaded": _loaded_chunks.has(chunk_coord),
		"chunk_seed": _chunk_seed(chunk_coord),
		"player_chunk": world_to_chunk(player_world_position),
		"loaded_chunk_count": _loaded_chunks.size()
	}


func get_runtime_debug_text(player_world_position: Vector2) -> String:
	var player_chunk := world_to_chunk(player_world_position)
	return "\n".join([
		"Seed: %d" % worldgen_settings.world_seed,
		"Player chunk: %s" % _format_vec2i(player_chunk),
		"Loaded chunks: %d" % _loaded_chunks.size(),
		"Chunk size: %d cells" % chunk_size,
		"Load / unload radius: %d / %d" % [load_radius, unload_radius],
		"Grid: %s" % _on_off(show_grid),
		"Chunk borders: %s" % _on_off(show_chunk_borders),
		"Biome overlay: %s" % _on_off(show_biome_overlay)
	])


func get_controls_text() -> String:
	return "\n".join([
		"WASD Move",
		"Mouse Wheel Zoom",
		"Hold Right Mouse Inspect Tile",
		"G Toggle Grid: %s" % _on_off(show_grid),
		"B Toggle Chunk Borders: %s" % _on_off(show_chunk_borders),
		"V Toggle Biome Overlay: %s" % _on_off(show_biome_overlay),
		"F1 Toggle Debug Panel",
		"R Randomize Seed + Reload",
		"Water blocks movement"
	])


func get_spawn_world_position() -> Vector2:
	var origin_cell := Vector2i.ZERO
	for radius in range(0, 24):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var cell := origin_cell + Vector2i(x, y)
				var sample := sample_world_cell(cell)
				if TerrainDefinitions.is_walkable(sample["terrain_id"]):
					return cell_to_world_center(cell)
	return Vector2.ZERO


func sample_world_cell(world_cell: Vector2i) -> Dictionary:
	return _generator.sample_tile(world_cell)


func get_loaded_chunk_coords() -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for chunk_coord in _loaded_chunks.keys():
		coords.append(chunk_coord)
	return coords


func get_worldgen_settings() -> WorldGenSettings:
	return worldgen_settings


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_position.x / float(cell_size))),
		int(floor(world_position.y / float(cell_size)))
	)


func world_to_chunk(world_position: Vector2) -> Vector2i:
	return cell_to_chunk(world_to_cell(world_position))


func cell_to_chunk(world_cell: Vector2i) -> Vector2i:
	return Vector2i(
		int(floor(world_cell.x / float(chunk_size))),
		int(floor(world_cell.y / float(chunk_size)))
	)


func cell_to_world_center(world_cell: Vector2i) -> Vector2:
	return Vector2(
		(world_cell.x + 0.5) * cell_size,
		(world_cell.y + 0.5) * cell_size
	)


func _update_loaded_chunks(center_chunk: Vector2i) -> void:
	if unload_radius < load_radius:
		unload_radius = load_radius + 1

	for y in range(center_chunk.y - load_radius, center_chunk.y + load_radius + 1):
		for x in range(center_chunk.x - load_radius, center_chunk.x + load_radius + 1):
			var chunk_coord := Vector2i(x, y)
			if not _loaded_chunks.has(chunk_coord):
				_load_chunk(chunk_coord)

	var to_remove: Array[Vector2i] = []
	for chunk_coord in _loaded_chunks.keys():
		var distance = max(abs(chunk_coord.x - center_chunk.x), abs(chunk_coord.y - center_chunk.y))
		if distance > unload_radius:
			to_remove.append(chunk_coord)

	for chunk_coord in to_remove:
		var chunk_node = _loaded_chunks[chunk_coord]
		chunk_unloaded.emit(chunk_coord)
		chunk_node.queue_free()
		_loaded_chunks.erase(chunk_coord)

	_last_player_chunk = center_chunk


func _load_chunk(chunk_coord: Vector2i) -> void:
	var chunk_data := ChunkDataClass.new(chunk_coord, chunk_size, _chunk_seed(chunk_coord))
	for local_y in range(chunk_size):
		for local_x in range(chunk_size):
			var world_cell := chunk_coord * chunk_size + Vector2i(local_x, local_y)
			var sample := sample_world_cell(world_cell)
			chunk_data.set_cell(local_x, local_y, sample)

	chunk_data.build_render_padding(Callable(self, "_terrain_id_at_world_cell"))

	var chunk_node = ChunkScene.instantiate()
	add_child(chunk_node)
	chunk_node.setup(chunk_data, _render_settings(), _debug_settings())
	_loaded_chunks[chunk_coord] = chunk_node
	chunk_loaded.emit(chunk_coord)


func _terrain_id_at_world_cell(world_cell: Vector2i) -> int:
	return sample_world_cell(world_cell)["terrain_id"]


func _render_settings() -> Dictionary:
	return {
		"cell_size": cell_size,
		"deep_water_color": worldgen_settings.deep_water_color,
		"shallow_water_color": worldgen_settings.shallow_water_color,
		"sand_color": worldgen_settings.sand_color,
		"dirt_color": worldgen_settings.dirt_color,
		"grass_color": worldgen_settings.grass_color,
		"jungle_ground_color": worldgen_settings.jungle_ground_color,
		"clay_color": worldgen_settings.clay_color,
		"stone_color": worldgen_settings.stone_color,
		"land_noise_strength": worldgen_settings.land_blend_noise_strength,
		"shoreline_noise_strength": worldgen_settings.shoreline_noise_strength,
		"land_blend_strength": worldgen_settings.land_blend_strength,
		"shoreline_blend_strength": worldgen_settings.shoreline_blend_strength,
		"shoreline_tint_strength": worldgen_settings.shoreline_tint_strength,
		"edge_noise_scale": worldgen_settings.edge_noise_scale,
		"pixel_variation": worldgen_settings.pixel_variation
	}


func _debug_settings() -> Dictionary:
	return {
		"show_grid": show_grid,
		"show_chunk_borders": show_chunk_borders,
		"show_biome_overlay": show_biome_overlay
	}


func _refresh_chunk_debug_options() -> void:
	for chunk_node in _loaded_chunks.values():
		chunk_node.set_debug_options(show_grid, show_chunk_borders, show_biome_overlay)


func _clear_loaded_chunks() -> void:
	for chunk_coord in _loaded_chunks.keys():
		chunk_unloaded.emit(chunk_coord)
		var chunk_node = _loaded_chunks[chunk_coord]
		chunk_node.queue_free()
	_loaded_chunks.clear()


func _configure_generator() -> void:
	if worldgen_settings == null:
		worldgen_settings = WorldGenSettingsClass.new()
	_generator.configure(worldgen_settings)


func _chunk_seed(chunk_coord: Vector2i) -> int:
	return int(worldgen_settings.world_seed + chunk_coord.x * 92821 + chunk_coord.y * 68917)


func _format_vec2i(value: Vector2i) -> String:
	return "(%d, %d)" % [value.x, value.y]


func _on_off(value: bool) -> String:
	return "ON" if value else "OFF"
