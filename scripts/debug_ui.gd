extends Control

@onready var controls_label: Label = $ControlsLabel
@onready var status_label: Label = $StatusLabel
@onready var tooltip_panel: PanelContainer = $TooltipPanel
@onready var tooltip_label: Label = $TooltipPanel/TooltipLabel


func set_controls_text(text: String) -> void:
	controls_label.text = text


func set_status_text(text: String) -> void:
	status_label.text = text


func show_tooltip(text: String, mouse_position: Vector2) -> void:
	tooltip_label.text = text
	tooltip_panel.visible = true
	tooltip_panel.reset_size()

	var tooltip_size := tooltip_panel.size
	if tooltip_size == Vector2.ZERO:
		tooltip_size = tooltip_panel.get_combined_minimum_size()
		tooltip_panel.size = tooltip_size

	var tooltip_offset := Vector2(18.0, 18.0)
	var next_position := mouse_position + tooltip_offset
	var viewport_rect := get_viewport_rect()

	if next_position.x + tooltip_size.x > viewport_rect.size.x - 12.0:
		next_position.x = mouse_position.x - tooltip_size.x - 18.0
	if next_position.y + tooltip_size.y > viewport_rect.size.y - 12.0:
		next_position.y = mouse_position.y - tooltip_size.y - 18.0

	next_position.x = clamp(next_position.x, 8.0, viewport_rect.size.x - tooltip_size.x - 8.0)
	next_position.y = clamp(next_position.y, 8.0, viewport_rect.size.y - tooltip_size.y - 8.0)
	tooltip_panel.position = next_position


func hide_tooltip() -> void:
	tooltip_panel.visible = false


func format_tile_info(tile_info: Dictionary) -> String:
	return "\n".join([
		"Tile Inspect",
		"World cell: %s" % _format_vec2i(tile_info.get("world_cell", Vector2i.ZERO)),
		"Chunk: %s" % _format_vec2i(tile_info.get("chunk_coord", Vector2i.ZERO)),
		"Local cell: %s" % _format_vec2i(tile_info.get("local_cell", Vector2i.ZERO)),
		"Landmass: %.3f" % float(tile_info.get("landmass", 0.0)),
		"Moisture: %.3f" % float(tile_info.get("moisture", 0.0)),
		"Temperature: %.3f" % float(tile_info.get("temperature", 0.0)),
		"Uplift: %.3f" % float(tile_info.get("uplift", 0.0)),
		"Biome: %s" % str(tile_info.get("biome_name", "Unknown")),
		"Terrain: %s" % str(tile_info.get("terrain_name", "Unknown")),
		"Walkable: %s" % _yes_no(bool(tile_info.get("walkable", false))),
		"Chunk loaded: %s" % _yes_no(bool(tile_info.get("loaded", false))),
		"Chunk seed: %d" % int(tile_info.get("chunk_seed", 0)),
		"Loaded chunks: %d" % int(tile_info.get("loaded_chunk_count", 0)),
		"Player chunk: %s" % _format_vec2i(tile_info.get("player_chunk", Vector2i.ZERO))
	])


func _format_vec2i(value: Vector2i) -> String:
	return "(%d, %d)" % [value.x, value.y]


func _yes_no(value: bool) -> String:
	return "Yes" if value else "No"
