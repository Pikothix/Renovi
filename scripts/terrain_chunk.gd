class_name TerrainChunk
extends Node2D

@onready var terrain_renderer = $Terrain
@onready var debug_draw = $DebugDraw

var chunk_data: ChunkData


func setup(data: ChunkData, render_settings: Dictionary, debug_settings: Dictionary) -> void:
	chunk_data = data
	position = Vector2(
		data.chunk_coord.x * data.chunk_size * render_settings["cell_size"],
		data.chunk_coord.y * data.chunk_size * render_settings["cell_size"]
	)
	terrain_renderer.setup(data, render_settings)
	debug_draw.setup(data, render_settings["cell_size"])
	debug_draw.set_visibility_flags(debug_settings["show_grid"], debug_settings["show_chunk_borders"], debug_settings["show_biome_overlay"])


func set_debug_options(show_grid: bool, show_chunk_borders: bool, show_biome_overlay: bool) -> void:
	debug_draw.set_visibility_flags(show_grid, show_chunk_borders, show_biome_overlay)
