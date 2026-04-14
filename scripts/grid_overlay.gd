extends Node2D

var _map_width := 0
var _map_height := 0
var _cell_size := 16


func setup(map_width: int, map_height: int, cell_size: int) -> void:
	_map_width = map_width
	_map_height = map_height
	_cell_size = cell_size
	queue_redraw()


func _draw() -> void:
	if _map_width == 0 or _map_height == 0:
		return

	var width_px := _map_width * _cell_size
	var height_px := _map_height * _cell_size
	var line_color := Color(0.07, 0.09, 0.1, 0.28)

	for x in range(_map_width + 1):
		var x_pos := x * _cell_size
		draw_line(Vector2(x_pos, 0), Vector2(x_pos, height_px), line_color, 1.0)

	for y in range(_map_height + 1):
		var y_pos := y * _cell_size
		draw_line(Vector2(0, y_pos), Vector2(width_px, y_pos), line_color, 1.0)

