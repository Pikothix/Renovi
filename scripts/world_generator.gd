class_name WorldGenerator
extends RefCounted

var _settings: WorldGenSettings
var _landmass_noise := FastNoiseLite.new()
var _moisture_noise := FastNoiseLite.new()
var _temperature_noise := FastNoiseLite.new()
var _uplift_noise := FastNoiseLite.new()


func configure(settings: WorldGenSettings) -> void:
	_settings = settings
	var noise_type = _settings.get_noise_type_enum()
	_configure_noise(_landmass_noise, _settings.world_seed + 101, _settings.landmass_frequency, noise_type)
	_configure_noise(_moisture_noise, _settings.world_seed + 202, _settings.moisture_frequency, noise_type)
	_configure_noise(_temperature_noise, _settings.world_seed + 303, _settings.temperature_frequency, noise_type)
	_configure_noise(_uplift_noise, _settings.world_seed + 404, _settings.uplift_frequency, noise_type)


func sample_tile(world_cell: Vector2i) -> Dictionary:
	var signals := sample_signals(world_cell)
	var biome_id := classify_biome(signals)
	var terrain_id := classify_terrain(signals, biome_id)
	return {
		"landmass": signals["landmass"],
		"moisture": signals["moisture"],
		"temperature": signals["temperature"],
		"uplift": signals["uplift"],
		"biome_id": biome_id,
		"terrain_id": terrain_id
	}


func sample_signals(world_cell: Vector2i) -> Dictionary:
	var landmass := _sample_noise(_landmass_noise, world_cell, _settings.landmass_offset)
	var moisture := _sample_noise(_moisture_noise, world_cell, _settings.moisture_offset)
	var temperature_noise := _sample_noise(_temperature_noise, world_cell, _settings.temperature_offset)
	var uplift := _sample_noise(_uplift_noise, world_cell, _settings.uplift_offset)
	var latitude = clamp(0.5 + world_cell.y * _settings.temperature_latitude_scale, 0.0, 1.0)
	var temperature = clamp(lerp(temperature_noise, latitude, _settings.temperature_latitude_strength), 0.0, 1.0)

	return {
		"landmass": landmass,
		"moisture": moisture,
		"temperature": temperature,
		"uplift": uplift
	}


func classify_biome(signals: Dictionary) -> int:
	var landmass: float = signals["landmass"]
	var moisture: float = signals["moisture"]
	var temperature: float = signals["temperature"]
	var uplift: float = signals["uplift"]

	if landmass < _settings.sea_level:
		return BiomeDefinitions.OCEAN
	if landmass < _settings.sea_level + _settings.coastline_width:
		return BiomeDefinitions.COAST
	if temperature >= _settings.jungle_temperature_threshold and moisture >= _settings.jungle_moisture_threshold:
		return BiomeDefinitions.JUNGLE
	if moisture >= _settings.wetland_moisture_threshold and landmass <= _settings.wetland_landmass_max and uplift <= _settings.wetland_uplift_max:
		return BiomeDefinitions.WETLAND
	if landmass >= _settings.rocky_upland_landmass_threshold or uplift >= _settings.rocky_upland_uplift_threshold or moisture <= _settings.rocky_dryness_threshold:
		return BiomeDefinitions.ROCKY_UPLAND
	return BiomeDefinitions.PLAINS


func classify_terrain(signals: Dictionary, biome_id: int) -> int:
	var landmass: float = signals["landmass"]
	var moisture: float = signals["moisture"]
	var temperature: float = signals["temperature"]
	var uplift: float = signals["uplift"]

	if landmass < _settings.deep_water_threshold:
		return TerrainDefinitions.DEEP_WATER
	if landmass < _settings.sea_level:
		return TerrainDefinitions.SHALLOW_WATER

	match biome_id:
		BiomeDefinitions.COAST:
			if landmass < _settings.sea_level + _settings.coastline_width * 0.65:
				return TerrainDefinitions.SAND
			if moisture > _settings.wetland_moisture_threshold:
				return TerrainDefinitions.GRASS
			return TerrainDefinitions.DIRT
		BiomeDefinitions.JUNGLE:
			if moisture >= _settings.jungle_moisture_threshold + 0.08 and temperature >= _settings.jungle_temperature_threshold + 0.05:
				return TerrainDefinitions.JUNGLE_GROUND
			if uplift >= _settings.rocky_upland_uplift_threshold:
				return TerrainDefinitions.DIRT
			return TerrainDefinitions.GRASS
		BiomeDefinitions.WETLAND:
			if landmass < _settings.sea_level + _settings.coastline_width * 0.25:
				return TerrainDefinitions.SHALLOW_WATER
			if moisture >= _settings.wetland_moisture_threshold + 0.10:
				return TerrainDefinitions.CLAY
			if moisture >= _settings.wetland_moisture_threshold:
				return TerrainDefinitions.DIRT
			return TerrainDefinitions.GRASS
		BiomeDefinitions.ROCKY_UPLAND:
			if uplift >= _settings.stone_uplift_threshold or landmass >= _settings.stone_landmass_threshold or moisture <= _settings.rocky_dryness_threshold:
				return TerrainDefinitions.STONE
			if moisture > 0.46 and temperature > 0.30:
				return TerrainDefinitions.GRASS
			return TerrainDefinitions.DIRT
		BiomeDefinitions.PLAINS:
			if moisture >= 0.46 and temperature >= 0.34:
				return TerrainDefinitions.GRASS
			return TerrainDefinitions.DIRT
		_:
			return TerrainDefinitions.DEEP_WATER


func _sample_noise(noise: FastNoiseLite, world_cell: Vector2i, offset: Vector2) -> float:
	return clamp((noise.get_noise_2d(world_cell.x + offset.x, world_cell.y + offset.y) + 1.0) * 0.5, 0.0, 1.0)


func _configure_noise(noise: FastNoiseLite, seed: int, frequency: float, noise_type: int) -> void:
	noise.seed = seed
	noise.frequency = frequency
	noise.fractal_octaves = _settings.fractal_octaves
	noise.fractal_lacunarity = _settings.fractal_lacunarity
	noise.fractal_gain = _settings.fractal_gain
	noise.noise_type = noise_type
