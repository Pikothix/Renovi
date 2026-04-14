extends Control

const OVERLAY_COLOR := Color(0, 0, 0, 0.92)

var _active := false
var _tile_size := 16
var _visible_world_tiles: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	set_process(false)


func _process(_delta: float) -> void:
	queue_redraw()


func set_overlay(active: bool, visible_world_tiles: Array[Vector2i], tile_size: int) -> void:
	_active = active
	_tile_size = tile_size
	_visible_world_tiles.clear()
	for cell in visible_world_tiles:
		_visible_world_tiles[cell] = true

	visible = active
	set_process(active)
	queue_redraw()


func _draw() -> void:
	if not _active:
		return

	var viewport_size := get_viewport_rect().size
	var canvas_transform := get_viewport().get_canvas_transform()
	var inverse_canvas := canvas_transform.affine_inverse()
	var world_top_left := inverse_canvas * Vector2.ZERO
	var world_bottom_right := inverse_canvas * viewport_size

	var min_world_x := minf(world_top_left.x, world_bottom_right.x)
	var max_world_x := maxf(world_top_left.x, world_bottom_right.x)
	var min_world_y := minf(world_top_left.y, world_bottom_right.y)
	var max_world_y := maxf(world_top_left.y, world_bottom_right.y)

	var min_cell_x := int(floor(min_world_x / float(_tile_size))) - 1
	var max_cell_x := int(floor(max_world_x / float(_tile_size))) + 1
	var min_cell_y := int(floor(min_world_y / float(_tile_size))) - 1
	var max_cell_y := int(floor(max_world_y / float(_tile_size))) + 1

	for y in range(min_cell_y, max_cell_y + 1):
		for x in range(min_cell_x, max_cell_x + 1):
			var world_cell := Vector2i(x, y)
			if _visible_world_tiles.has(world_cell):
				continue

			var world_top_left_px := Vector2(world_cell.x * _tile_size, world_cell.y * _tile_size)
			var world_bottom_right_px := world_top_left_px + Vector2.ONE * _tile_size
			var screen_top_left := canvas_transform * world_top_left_px
			var screen_bottom_right := canvas_transform * world_bottom_right_px
			var screen_rect := Rect2(screen_top_left, screen_bottom_right - screen_top_left).abs()
			draw_rect(screen_rect, OVERLAY_COLOR)
