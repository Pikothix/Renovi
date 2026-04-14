class_name ChunkData
extends RefCounted

var chunk_coord: Vector2i
var chunk_size: int
var chunk_seed: int

var terrain_ids: PackedByteArray = PackedByteArray()
var biome_ids: PackedByteArray = PackedByteArray()
var landmass_values: PackedFloat32Array = PackedFloat32Array()
var moisture_values: PackedFloat32Array = PackedFloat32Array()
var temperature_values: PackedFloat32Array = PackedFloat32Array()
var uplift_values: PackedFloat32Array = PackedFloat32Array()
var render_terrain_ids: PackedByteArray = PackedByteArray()


func _init(p_chunk_coord: Vector2i, p_chunk_size: int, p_chunk_seed: int) -> void:
	chunk_coord = p_chunk_coord
	chunk_size = p_chunk_size
	chunk_seed = p_chunk_seed
	terrain_ids.resize(chunk_size * chunk_size)
	biome_ids.resize(chunk_size * chunk_size)
	landmass_values.resize(chunk_size * chunk_size)
	moisture_values.resize(chunk_size * chunk_size)
	temperature_values.resize(chunk_size * chunk_size)
	uplift_values.resize(chunk_size * chunk_size)


func set_cell(local_x: int, local_y: int, tile_data: Dictionary) -> void:
	var index := _index(local_x, local_y)
	terrain_ids[index] = int(tile_data["terrain_id"])
	biome_ids[index] = int(tile_data["biome_id"])
	landmass_values[index] = float(tile_data["landmass"])
	moisture_values[index] = float(tile_data["moisture"])
	temperature_values[index] = float(tile_data["temperature"])
	uplift_values[index] = float(tile_data["uplift"])


func get_terrain_id(local_x: int, local_y: int) -> int:
	return terrain_ids[_index(local_x, local_y)]


func get_biome_id(local_x: int, local_y: int) -> int:
	return biome_ids[_index(local_x, local_y)]


func get_tile_data(local_x: int, local_y: int) -> Dictionary:
	var index := _index(local_x, local_y)
	return {
		"terrain_id": int(terrain_ids[index]),
		"biome_id": int(biome_ids[index]),
		"landmass": float(landmass_values[index]),
		"moisture": float(moisture_values[index]),
		"temperature": float(temperature_values[index]),
		"uplift": float(uplift_values[index])
	}


func build_render_padding(terrain_lookup: Callable) -> void:
	var padded_size := chunk_size + 2
	render_terrain_ids.resize(padded_size * padded_size)

	for y in range(-1, chunk_size + 1):
		for x in range(-1, chunk_size + 1):
			var world_cell := chunk_coord * chunk_size + Vector2i(x, y)
			var padded_index := (y + 1) * padded_size + (x + 1)
			render_terrain_ids[padded_index] = int(terrain_lookup.call(world_cell))


func create_render_texture() -> ImageTexture:
	var padded_size := chunk_size + 2
	var image := Image.create(padded_size, padded_size, false, Image.FORMAT_RGBA8)

	for y in range(padded_size):
		for x in range(padded_size):
			var terrain_id := render_terrain_ids[y * padded_size + x]
			var encoded_red := float(terrain_id) / 7.0
			image.set_pixel(x, y, Color(encoded_red, 0.0, 0.0, 1.0))

	return ImageTexture.create_from_image(image)


func _index(local_x: int, local_y: int) -> int:
	return local_y * chunk_size + local_x
