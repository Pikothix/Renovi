@tool
extends PanelContainer

const WorldGeneratorClass = preload("res://scripts/world_generator.gd")

@onready var landmass_rect: TextureRect = $Margin/VBox/Maps/Landmass/Texture
@onready var temperature_rect: TextureRect = $Margin/VBox/Maps/Temperature/Texture
@onready var moisture_rect: TextureRect = $Margin/VBox/Maps/Moisture/Texture
@onready var biome_rect: TextureRect = $Margin/VBox/Maps/Biome/Texture

var _settings: WorldGenSettings
var _refresh_timer := 0.0
var _last_signature := ""


func _ready() -> void:
	if not Engine.is_editor_hint():
		visible = true


func _process(delta: float) -> void:
	_refresh_timer -= delta
	if _refresh_timer > 0.0:
		return
	_refresh_timer = 0.5

	var chunk_manager = get_node_or_null("../../../World/ChunkManager")
	if chunk_manager == null:
		return

	var settings = chunk_manager.get_worldgen_settings()
	if settings == null:
		return

	var signature := _build_signature(settings, chunk_manager)
	if signature == _last_signature:
		return

	_settings = settings
	_last_signature = signature
	_refresh_previews(chunk_manager)


func _refresh_previews(chunk_manager: Node) -> void:
	var generator := WorldGeneratorClass.new()
	generator.configure(_settings)

	landmass_rect.texture = _build_signal_texture(generator, "landmass")
	temperature_rect.texture = _build_signal_texture(generator, "temperature")
	moisture_rect.texture = _build_signal_texture(generator, "moisture")
	biome_rect.texture = _build_biome_texture(generator)
	biome_rect.visible = _settings.preview_show_biome_map
	$Margin/VBox/Maps/Biome.visible = _settings.preview_show_biome_map


func _build_signal_texture(generator: WorldGenerator, signal_name: String) -> Texture2D:
	var image := Image.create(_settings.preview_size, _settings.preview_size, false, Image.FORMAT_RGBA8)
	for y in range(_settings.preview_size):
		for x in range(_settings.preview_size):
			var world_cell := _preview_to_world_cell(x, y)
			var signals := generator.sample_signals(world_cell)
			var value := float(signals[signal_name])
			image.set_pixel(x, y, Color(value, value, value, 1.0))
	return ImageTexture.create_from_image(image)


func _build_biome_texture(generator: WorldGenerator) -> Texture2D:
	var image := Image.create(_settings.preview_size, _settings.preview_size, false, Image.FORMAT_RGBA8)
	for y in range(_settings.preview_size):
		for x in range(_settings.preview_size):
			var world_cell := _preview_to_world_cell(x, y)
			var tile_data := generator.sample_tile(world_cell)
			var biome_color := BiomeDefinitions.get_debug_color(int(tile_data["biome_id"]))
			image.set_pixel(x, y, biome_color)
	return ImageTexture.create_from_image(image)


func _preview_to_world_cell(x: int, y: int) -> Vector2i:
	var normalized := Vector2(float(x) / max(1.0, _settings.preview_size - 1.0), float(y) / max(1.0, _settings.preview_size - 1.0))
	var world_offset := (normalized - Vector2.ONE * 0.5) * _settings.preview_world_span
	return Vector2i(int(round(world_offset.x)), int(round(world_offset.y)))


func _build_signature(settings: WorldGenSettings, chunk_manager: Node) -> String:
	return str([
		settings.world_seed,
		chunk_manager.get("chunk_size"),
		settings.noise_type,
		settings.fractal_octaves,
		settings.fractal_gain,
		settings.landmass_frequency,
		settings.moisture_frequency,
		settings.temperature_frequency,
		settings.uplift_frequency,
		settings.landmass_offset,
		settings.moisture_offset,
		settings.temperature_offset,
		settings.uplift_offset,
		settings.temperature_latitude_scale,
		settings.temperature_latitude_strength,
		settings.deep_water_threshold,
		settings.sea_level,
		settings.coastline_width,
		settings.jungle_temperature_threshold,
		settings.jungle_moisture_threshold,
		settings.wetland_moisture_threshold,
		settings.wetland_landmass_max,
		settings.wetland_uplift_max,
		settings.rocky_upland_landmass_threshold,
		settings.rocky_upland_uplift_threshold,
		settings.rocky_dryness_threshold,
		settings.stone_uplift_threshold,
		settings.stone_landmass_threshold,
		settings.preview_size,
		settings.preview_world_span,
		settings.preview_show_biome_map
	])
