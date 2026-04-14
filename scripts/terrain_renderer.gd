extends Sprite2D

const TERRAIN_SHADER := preload("res://shaders/terrain_blend.gdshader")

var _chunk_data
var _white_texture: Texture2D


func setup(chunk_data, render_settings: Dictionary) -> void:
	_chunk_data = chunk_data
	_ensure_base_texture()
	_apply_material(render_settings)


func _ensure_base_texture() -> void:
	if _white_texture == null:
		var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		image.set_pixel(0, 0, Color.WHITE)
		_white_texture = ImageTexture.create_from_image(image)

	texture = _white_texture
	centered = false
	position = Vector2.ZERO
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _apply_material(render_settings: Dictionary) -> void:
	scale = Vector2(_chunk_data.chunk_size * render_settings["cell_size"], _chunk_data.chunk_size * render_settings["cell_size"])

	var shader_material := material as ShaderMaterial
	if shader_material == null:
		shader_material = ShaderMaterial.new()
		shader_material.shader = TERRAIN_SHADER
		material = shader_material

	shader_material.set_shader_parameter("terrain_map", _chunk_data.create_render_texture())
	shader_material.set_shader_parameter("logical_map_cells", Vector2(_chunk_data.chunk_size, _chunk_data.chunk_size))
	shader_material.set_shader_parameter("padded_map_cells", Vector2(_chunk_data.chunk_size + 2, _chunk_data.chunk_size + 2))
	shader_material.set_shader_parameter("cell_size_px", float(render_settings["cell_size"]))
	shader_material.set_shader_parameter("deep_water_color", render_settings["deep_water_color"])
	shader_material.set_shader_parameter("shallow_water_color", render_settings["shallow_water_color"])
	shader_material.set_shader_parameter("sand_color", render_settings["sand_color"])
	shader_material.set_shader_parameter("dirt_color", render_settings["dirt_color"])
	shader_material.set_shader_parameter("grass_color", render_settings["grass_color"])
	shader_material.set_shader_parameter("jungle_ground_color", render_settings["jungle_ground_color"])
	shader_material.set_shader_parameter("clay_color", render_settings["clay_color"])
	shader_material.set_shader_parameter("stone_color", render_settings["stone_color"])
	shader_material.set_shader_parameter("land_noise_strength", render_settings["land_noise_strength"])
	shader_material.set_shader_parameter("shoreline_noise_strength", render_settings["shoreline_noise_strength"])
	shader_material.set_shader_parameter("land_blend_strength", render_settings["land_blend_strength"])
	shader_material.set_shader_parameter("shoreline_blend_strength", render_settings["shoreline_blend_strength"])
	shader_material.set_shader_parameter("shoreline_tint_strength", render_settings["shoreline_tint_strength"])
	shader_material.set_shader_parameter("pixel_variation", render_settings["pixel_variation"])
	shader_material.set_shader_parameter("edge_noise_scale", render_settings["edge_noise_scale"])
