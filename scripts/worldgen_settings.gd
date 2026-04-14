@tool
class_name WorldGenSettings
extends Resource

@export_group("World Seed")
@export var world_seed: int = 12345

@export_group("Signal Noise")
@export_enum("Simplex", "Cellular", "Perlin", "Value", "Value Cubic") var noise_type: int = 0
@export_range(1, 6, 1) var fractal_octaves: int = 3
@export_range(0.0, 4.0, 0.01) var fractal_lacunarity: float = 2.0
@export_range(0.0, 1.0, 0.01) var fractal_gain: float = 0.55
@export_range(0.001, 0.2, 0.001) var landmass_frequency: float = 0.010
@export_range(0.001, 0.2, 0.001) var moisture_frequency: float = 0.021
@export_range(0.001, 0.2, 0.001) var temperature_frequency: float = 0.015
@export_range(0.001, 0.2, 0.001) var uplift_frequency: float = 0.034
@export var landmass_offset := Vector2(0.0, 0.0)
@export var moisture_offset := Vector2(1700.0, 900.0)
@export var temperature_offset := Vector2(-1400.0, 2300.0)
@export var uplift_offset := Vector2(3200.0, -1250.0)
@export_range(0.0, 0.02, 0.0001) var temperature_latitude_scale: float = 0.0008
@export_range(0.0, 1.0, 0.01) var temperature_latitude_strength: float = 0.25

@export_group("Classification Thresholds")
@export_range(0.0, 1.0, 0.01) var deep_water_threshold: float = 0.22
@export_range(0.0, 1.0, 0.01) var sea_level: float = 0.31
@export_range(0.0, 0.3, 0.01) var coastline_width: float = 0.07
@export_range(0.0, 1.0, 0.01) var jungle_temperature_threshold: float = 0.62
@export_range(0.0, 1.0, 0.01) var jungle_moisture_threshold: float = 0.66
@export_range(0.0, 1.0, 0.01) var wetland_moisture_threshold: float = 0.72
@export_range(0.0, 1.0, 0.01) var wetland_landmass_max: float = 0.52
@export_range(0.0, 1.0, 0.01) var wetland_uplift_max: float = 0.44
@export_range(0.0, 1.0, 0.01) var rocky_upland_landmass_threshold: float = 0.67
@export_range(0.0, 1.0, 0.01) var rocky_upland_uplift_threshold: float = 0.62
@export_range(0.0, 1.0, 0.01) var rocky_dryness_threshold: float = 0.30
@export_range(0.0, 1.0, 0.01) var stone_uplift_threshold: float = 0.74
@export_range(0.0, 1.0, 0.01) var stone_landmass_threshold: float = 0.78

@export_group("Terrain Colors")
@export var deep_water_color := Color("2d5ea7")
@export var shallow_water_color := Color("5a9be0")
@export var sand_color := Color("d9c16d")
@export var dirt_color := Color("8b5a3c")
@export var grass_color := Color("5fba61")
@export var jungle_ground_color := Color("2f7a3d")
@export var clay_color := Color("a8a39b")
@export var stone_color := Color("4f555d")

@export_group("Rendering")
@export_range(0.0, 0.35, 0.01) var land_blend_noise_strength := 0.15
@export_range(0.0, 0.35, 0.01) var shoreline_noise_strength := 0.08
@export_range(0.01, 0.5, 0.01) var land_blend_strength := 0.12
@export_range(0.01, 0.4, 0.01) var shoreline_blend_strength := 0.07
@export_range(0.0, 0.25, 0.01) var shoreline_tint_strength := 0.08
@export_range(0.5, 8.0, 0.1) var edge_noise_scale := 2.6
@export_range(0.0, 0.2, 0.01) var pixel_variation := 0.06

@export_group("Preview")
@export_range(64, 512, 1) var preview_size: int = 192
@export_range(64.0, 4096.0, 1.0) var preview_world_span: float = 768.0
@export var preview_show_biome_map: bool = true


func get_noise_type_enum():
	match noise_type:
		1:
			return FastNoiseLite.TYPE_CELLULAR
		2:
			return FastNoiseLite.TYPE_PERLIN
		3:
			return FastNoiseLite.TYPE_VALUE
		4:
			return FastNoiseLite.TYPE_VALUE_CUBIC
		_:
			return FastNoiseLite.TYPE_SIMPLEX
