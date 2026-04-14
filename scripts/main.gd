extends Node2D

@onready var world = $World
@onready var player = $Player
@onready var debug_ui = $CanvasLayer/DebugUI


func _ready() -> void:
	world.set_player(player)
	player.set_world(world)
	player.global_position = world.get_spawn_world_position()
	debug_ui.set_controls_text(world.get_controls_text())
	debug_ui.set_status_text(world.get_runtime_debug_text(player.global_position))
	debug_ui.hide_tooltip()
	debug_ui.visible = world.is_debug_panel_visible()


func _process(_delta: float) -> void:
	debug_ui.set_status_text(world.get_runtime_debug_text(player.global_position))

	if debug_ui.visible and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var mouse_position := get_viewport().get_mouse_position()
		var tile_info = world.inspect_world_position(get_global_mouse_position(), player.global_position)
		debug_ui.show_tooltip(debug_ui.format_tile_info(tile_info), mouse_position)
	else:
		debug_ui.hide_tooltip()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_G:
				world.toggle_grid()
				_refresh_debug_ui()
			KEY_B:
				world.toggle_chunk_borders()
				_refresh_debug_ui()
			KEY_V:
				world.toggle_biome_overlay()
				_refresh_debug_ui()
			KEY_F1:
				world.toggle_debug_panel()
				_refresh_debug_ui()
			KEY_R:
				world.regenerate_world(true)
				player.global_position = world.get_spawn_world_position()
				_refresh_debug_ui()


func _refresh_debug_ui() -> void:
	debug_ui.set_controls_text(world.get_controls_text())
	debug_ui.visible = world.is_debug_panel_visible()
