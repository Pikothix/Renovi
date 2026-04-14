extends Node2D

var _chunk_data: ChunkData
var _chunk_coord := Vector2i.ZERO
var _chunk_size := 16
var _cell_size := 16
var _show_grid := false
var _show_chunk_borders := true
var _show_biome_overlay := false


func setup(chunk_data: ChunkData, cell_size: int) -> void:
	_chunk_data = chunk_data
	_chunk_coord = chunk_data.chunk_coord
	_chunk_size = chunk_data.chunk_size
	_cell_size = cell_size
	queue_redraw()


func set_visibility_flags(show_grid: bool, show_chunk_borders: bool, show_biome_overlay: bool) -> void:
	_show_grid = show_grid
	_show_chunk_borders = show_chunk_borders
	_show_biome_overlay = show_biome_overlay
	queue_redraw()


func _draw() -> void:
	var size_px := _chunk_size * _cell_size

	if _show_biome_overlay and _chunk_data != null:
		for y in range(_chunk_size):
			for x in range(_chunk_size):
				var biome_id := _chunk_data.get_biome_id(x, y)
				var biome_color := BiomeDefinitions.get_debug_color(biome_id)
				biome_color.a = 0.22
				draw_rect(Rect2(x * _cell_size, y * _cell_size, _cell_size, _cell_size), biome_color, true)

	if _show_grid:
		var grid_color := Color(0.08, 0.1, 0.12, 0.23)
		for x in range(_chunk_size + 1):
			var x_pos := x * _cell_size
			draw_line(Vector2(x_pos, 0), Vector2(x_pos, size_px), grid_color, 1.0)

		for y in range(_chunk_size + 1):
			var y_pos := y * _cell_size
			draw_line(Vector2(0, y_pos), Vector2(size_px, y_pos), grid_color, 1.0)

	if _show_chunk_borders:
		draw_rect(Rect2(Vector2.ZERO, Vector2(size_px, size_px)), Color(0.95, 0.95, 1.0, 0.5), false, 2.0)
