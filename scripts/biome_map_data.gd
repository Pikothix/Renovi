class_name BiomeMapData
extends RefCounted

const BIOME_GRASS := 0
const BIOME_SAND := 1
const BIOME_DIRT := 2
const BIOME_WATER := 3

var width: int
var height: int
var seed: int
var _biomes: PackedByteArray = PackedByteArray()


func _init(p_width: int, p_height: int, p_seed: int = 0) -> void:
	width = p_width
	height = p_height
	seed = p_seed if p_seed != 0 else int(Time.get_unix_time_from_system())


func generate() -> void:
	_biomes.resize(width * height)

	var shape_noise := FastNoiseLite.new()
	shape_noise.seed = seed
	shape_noise.frequency = 0.035
	shape_noise.fractal_octaves = 3
	shape_noise.fractal_gain = 0.55

	var detail_noise := FastNoiseLite.new()
	detail_noise.seed = seed + 917
	detail_noise.frequency = 0.09
	detail_noise.fractal_octaves = 2
	detail_noise.fractal_gain = 0.5

	var grass_anchor := Vector2(width * 0.23, height * 0.30)
	var sand_anchor := Vector2(width * 0.75, height * 0.28)
	var dirt_anchor := Vector2(width * 0.55, height * 0.78)

	for y in range(height):
		for x in range(width):
			var pos := Vector2(x, y)
			var warp := shape_noise.get_noise_2d(x, y) * 6.0
			var detail := detail_noise.get_noise_2d(x, y) * 2.5

			var grass_score := pos.distance_to(grass_anchor) + warp + detail
			var sand_score := pos.distance_to(sand_anchor) - warp * 0.4 - detail * 0.6
			var dirt_score := pos.distance_to(dirt_anchor) + detail - warp * 0.2

			var biome := BIOME_GRASS
			if sand_score < grass_score and sand_score < dirt_score:
				biome = BIOME_SAND
			elif dirt_score < grass_score and dirt_score < sand_score:
				biome = BIOME_DIRT

			set_biome(x, y, biome)

	_apply_water()
	_apply_shoreline_sand_bias()
	_force_three_way_intersection()
	_force_water_examples()


func create_biome_texture() -> ImageTexture:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)

	for y in range(height):
		for x in range(width):
			var biome := get_biome(x, y)
			var encoded_red := 0.0
			match biome:
				BIOME_GRASS:
					encoded_red = 0.0
				BIOME_SAND:
					encoded_red = 0.33333334
				BIOME_DIRT:
					encoded_red = 0.6666667
				BIOME_WATER:
					encoded_red = 1.0
			image.set_pixel(x, y, Color(encoded_red, 0.0, 0.0, 1.0))

	return ImageTexture.create_from_image(image)


func get_biome(x: int, y: int) -> int:
	return _biomes[_index(x, y)]


func set_biome(x: int, y: int, biome: int) -> void:
	_biomes[_index(x, y)] = biome


func is_walkable(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= width or y >= height:
		return false
	return get_biome(x, y) != BIOME_WATER


func _index(x: int, y: int) -> int:
	return y * width + x


func _apply_water() -> void:
	var lake_noise := FastNoiseLite.new()
	lake_noise.seed = seed + 211
	lake_noise.frequency = 0.07
	lake_noise.fractal_octaves = 3
	lake_noise.fractal_gain = 0.55

	var shoreline_noise := FastNoiseLite.new()
	shoreline_noise.seed = seed + 777
	shoreline_noise.frequency = 0.11
	shoreline_noise.fractal_octaves = 2
	shoreline_noise.fractal_gain = 0.45

	var lake_centers := [
		Vector2(width * 0.24, height * 0.66),
		Vector2(width * 0.78, height * 0.60),
		Vector2(width * 0.48, height * 0.18)
	]
	var lake_radii := [12.0, 10.0, 8.0]

	for y in range(height):
		for x in range(width):
			var lake_score := -10.0
			for i in range(lake_centers.size()):
				var center: Vector2 = lake_centers[i]
				var radius: float = lake_radii[i]
				var dist := center.distance_to(Vector2(x, y))
				var shape := 1.0 - (dist / radius)
				lake_score = max(lake_score, shape)

			var noise_bonus := lake_noise.get_noise_2d(x, y) * 0.45
			var shore_warp := shoreline_noise.get_noise_2d(x, y) * 0.18
			if lake_score + noise_bonus + shore_warp > 0.22:
				set_biome(x, y, BIOME_WATER)


func _apply_shoreline_sand_bias() -> void:
	var original := _biomes.duplicate()

	for y in range(height):
		for x in range(width):
			var index := _index(x, y)
			if original[index] == BIOME_WATER:
				continue

			var nearby_water := 0
			var nearby_land := 0
			for offset_y in range(-1, 2):
				for offset_x in range(-1, 2):
					if offset_x == 0 and offset_y == 0:
						continue
					var nx := x + offset_x
					var ny := y + offset_y
					if nx < 0 or ny < 0 or nx >= width or ny >= height:
						continue
					if original[_index(nx, ny)] == BIOME_WATER:
						nearby_water += 1
					else:
						nearby_land += 1

			if nearby_water >= 2 and nearby_land >= 2:
				set_biome(x, y, BIOME_SAND)


func _force_three_way_intersection() -> void:
	var center_x := width / 2
	var center_y := height / 2

	for y in range(center_y - 4, center_y + 5):
		for x in range(center_x - 4, center_x + 5):
			if x < 0 or y < 0 or x >= width or y >= height:
				continue

			if x <= center_x and y <= center_y:
				set_biome(x, y, BIOME_GRASS)
			elif x > center_x and y <= center_y:
				set_biome(x, y, BIOME_SAND)
			else:
				set_biome(x, y, BIOME_DIRT)


func _force_water_examples() -> void:
	var meeting_origin := Vector2i(width * 0.18, height * 0.18)

	for y in range(meeting_origin.y - 4, meeting_origin.y + 5):
		for x in range(meeting_origin.x - 4, meeting_origin.x + 5):
			if x < 0 or y < 0 or x >= width or y >= height:
				continue

			if x <= meeting_origin.x and y <= meeting_origin.y:
				set_biome(x, y, BIOME_WATER)
			elif x > meeting_origin.x and y <= meeting_origin.y:
				set_biome(x, y, BIOME_SAND)
			else:
				set_biome(x, y, BIOME_GRASS)

	var stress_center := Vector2i(width * 0.70, height * 0.72)
	for y in range(stress_center.y - 3, stress_center.y + 4):
		for x in range(stress_center.x - 7, stress_center.x + 8):
			if x < 0 or y < 0 or x >= width or y >= height:
				continue

			var distance_to_center = abs(y - stress_center.y) + abs(x - stress_center.x) * 0.35
			if distance_to_center < 3.2:
				set_biome(x, y, BIOME_WATER)
			elif distance_to_center < 4.2:
				set_biome(x, y, BIOME_SAND)

	var dirt_pond_center := Vector2i(width * 0.60, height * 0.84)
	for y in range(dirt_pond_center.y - 4, dirt_pond_center.y + 5):
		for x in range(dirt_pond_center.x - 4, dirt_pond_center.x + 5):
			if x < 0 or y < 0 or x >= width or y >= height:
				continue

			var pond_distance := Vector2(x, y).distance_to(Vector2(dirt_pond_center))
			if pond_distance < 2.8:
				set_biome(x, y, BIOME_WATER)
			elif pond_distance < 4.1:
				set_biome(x, y, BIOME_DIRT)
