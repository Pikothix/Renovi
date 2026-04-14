extends CharacterBody2D

@export var move_speed := 160.0
@export_range(2.0, 10.0, 1.0) var collision_padding := 6.0
@export_range(0.3, 3.0, 0.05) var min_zoom := 0.6
@export_range(0.3, 3.0, 0.05) var max_zoom := 2.2
@export_range(0.02, 0.5, 0.01) var zoom_step := 0.12
@export_range(0.3, 3.0, 0.05) var default_zoom := 1.1

@onready var camera: Camera2D = $Camera2D

var world: Node = null


func _ready() -> void:
	camera.zoom = Vector2.ONE * default_zoom


func _physics_process(delta: float) -> void:
	var input_vector := Vector2(
		int(Input.is_physical_key_pressed(KEY_D)) - int(Input.is_physical_key_pressed(KEY_A)),
		int(Input.is_physical_key_pressed(KEY_S)) - int(Input.is_physical_key_pressed(KEY_W))
	).normalized()

	velocity = input_vector * move_speed
	_move_with_terrain_collision(delta)
	if world != null:
		world.notify_player_world_position(global_position)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
		if world != null:
			world.try_interact(global_position)
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(camera.zoom.x - zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(camera.zoom.x + zoom_step)


func set_world(world_node: Node) -> void:
	world = world_node


func _set_zoom(next_zoom: float) -> void:
	var clamped_zoom = clamp(next_zoom, min_zoom, max_zoom)
	camera.zoom = Vector2.ONE * clamped_zoom


func _move_with_terrain_collision(delta: float) -> void:
	if world == null:
		move_and_slide()
		return

	var step := velocity * delta
	var next_x := global_position + Vector2(step.x, 0.0)
	if world.is_world_position_walkable(next_x, collision_padding):
		global_position.x = next_x.x
	else:
		velocity.x = 0.0

	var next_y := global_position + Vector2(0.0, step.y)
	if world.is_world_position_walkable(next_y, collision_padding):
		global_position.y = next_y.y
	else:
		velocity.y = 0.0
