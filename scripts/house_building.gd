class_name HouseBuilding
extends Node2D

signal entered(house: HouseBuilding)
signal exited(house: HouseBuilding)

@export var definition: HouseDefinition
@export_range(8, 64, 1) var cell_size := 16

var _inside := false
var _interior_exit_armed := false
var _layers: Dictionary = {}
var _exterior_root: Node2D
var _interior_root: Node2D


func _ready() -> void:
	_ensure_layer_roots()
	_ensure_layers()
	_rebuild()


func configure(house_definition: HouseDefinition, new_cell_size: int) -> void:
	definition = house_definition
	cell_size = new_cell_size
	if is_node_ready():
		_rebuild()


func set_interior_active(active: bool) -> void:
	# The same house instance flips between exterior layers and the bordered interior layers.
	_inside = active
	_exterior_root.visible = not active
	_interior_root.visible = active


func is_inside() -> bool:
	return _inside


func can_enter_from_world_position(world_position: Vector2) -> bool:
	var required_cell := definition.door_local_tile + Vector2i.DOWN
	return _world_to_local_cell(world_position) == required_cell


func blocks_world_position(world_position: Vector2) -> bool:
	return _is_footprint_cell(_world_to_local_cell(world_position))


func is_interior_world_position_walkable(world_position: Vector2) -> bool:
	var local_cell := _world_to_local_cell(world_position)
	return _is_footprint_cell(local_cell) or local_cell == definition.interior_exit_local_tile


func is_on_interior_exit_tile(world_position: Vector2) -> bool:
	return _world_to_local_cell(world_position) == definition.interior_exit_local_tile


func should_exit_for_world_position(world_position: Vector2) -> bool:
	if not _inside:
		return false

	var on_exit_tile := is_on_interior_exit_tile(world_position)
	if not _interior_exit_armed:
		if not on_exit_tile:
			_interior_exit_armed = true
		return false

	return on_exit_tile


func get_interior_spawn_world_position() -> Vector2:
	return _local_cell_to_world_center(definition.interior_spawn_local_tile)


func get_outside_exit_world_position() -> Vector2:
	return _local_cell_to_world_center(definition.door_local_tile + Vector2i.DOWN)


func get_border_world_rect() -> Rect2:
	var border_rect := definition.get_border_rect()
	return Rect2(
		global_position + Vector2(border_rect.position * cell_size),
		Vector2(border_rect.size * cell_size)
	)


func get_visible_interior_world_cells() -> Array[Vector2i]:
	var world_cells: Array[Vector2i] = []
	var anchor_world_cell := _anchor_world_cell()
	for local_cell in definition.get_visible_interior_tiles():
		world_cells.append(anchor_world_cell + local_cell)
	return world_cells


func get_occupied_world_cells() -> Array[Vector2i]:
	var world_cells: Array[Vector2i] = []
	var seen: Dictionary = {}
	var anchor_world_cell := _anchor_world_cell()

	for local_cell in definition.get_floor_cells():
		var world_cell := anchor_world_cell + local_cell
		if seen.has(world_cell):
			continue
		seen[world_cell] = true
		world_cells.append(world_cell)

	for local_cell in definition.get_visible_interior_tiles():
		var world_cell := anchor_world_cell + local_cell
		if seen.has(world_cell):
			continue
		seen[world_cell] = true
		world_cells.append(world_cell)

	return world_cells


func enter() -> void:
	_interior_exit_armed = false
	set_interior_active(true)
	entered.emit(self)


func exit() -> void:
	set_interior_active(false)
	exited.emit(self)


func _rebuild() -> void:
	if definition == null:
		return

	var tileset := HouseTileSetFactory.get_tileset()
	for layer in _layers.values():
		layer.tile_set = tileset
		layer.clear()

	# Future house variants should be added as more HouseDefinition resources.
	for placement in definition.exterior_tiles:
		_set_tile(_layers[placement.layer], placement)

	# The interior visible area is the 3x3 footprint plus north wall visuals at y = -2..-1.
	for cell in definition.get_floor_cells():
		_set_tile_from_values(
			_layers[&"floor"],
			cell,
			definition.floor_atlas_group,
			definition.floor_atlas_coords
		)

	for wall_tile in definition.get_inner_wall_cells():
		_set_tile_from_values(
			_layers[&"inner_wall"],
			wall_tile["cell"],
			wall_tile["atlas_group"],
			wall_tile["atlas_coords"]
		)

	_set_tile_from_values(
		_layers[&"interior_detail"],
		definition.interior_exit_marker_local_tile,
		definition.interior_exit_marker_atlas_group,
		definition.interior_exit_marker_atlas_coords
	)

	# Border bounds wrap the whole visible interior block, not the footprint alone.
	for border_tile in definition.get_border_tiles():
		_set_tile_from_values(
			_layers[&"border"],
			border_tile["cell"],
			border_tile["atlas_group"],
			border_tile["atlas_coords"]
		)

	set_interior_active(_inside)


func _ensure_layer_roots() -> void:
	_exterior_root = get_node_or_null("Exterior")
	if _exterior_root == null:
		_exterior_root = Node2D.new()
		_exterior_root.name = "Exterior"
		add_child(_exterior_root)

	_interior_root = get_node_or_null("Interior")
	if _interior_root == null:
		_interior_root = Node2D.new()
		_interior_root.name = "Interior"
		add_child(_interior_root)


func _ensure_layers() -> void:
	_layers[&"wall"] = _get_or_create_layer(_exterior_root, "Wall", 4)
	_layers[&"roof"] = _get_or_create_layer(_exterior_root, "Roof", 5)
	_layers[&"detail"] = _get_or_create_layer(_exterior_root, "Detail", 6)
	_layers[&"floor"] = _get_or_create_layer(_interior_root, "Floor", 4)
	_layers[&"interior_detail"] = _get_or_create_layer(_interior_root, "InteriorDetail", 11)
	_layers[&"inner_wall"] = _get_or_create_layer(_interior_root, "InnerWall", 9)
	_layers[&"border"] = _get_or_create_layer(_interior_root, "Border", 10)


func _get_or_create_layer(parent_node: Node2D, node_name: String, z_order: int) -> TileMapLayer:
	var layer := parent_node.get_node_or_null(node_name) as TileMapLayer
	if layer == null:
		layer = TileMapLayer.new()
		layer.name = node_name
		parent_node.add_child(layer)
	layer.z_index = z_order
	return layer


func _set_tile(layer: TileMapLayer, placement: HouseTilePlacement) -> void:
	_set_tile_from_values(layer, placement.cell, placement.atlas_group, placement.atlas_coords)


func _set_tile_from_values(layer: TileMapLayer, cell: Vector2i, atlas_group: StringName, atlas_coords: Vector2i) -> void:
	layer.set_cell(cell, HouseTileSetFactory.get_source_id(atlas_group), atlas_coords)


func _local_cell_to_world_center(local_cell: Vector2i) -> Vector2:
	var floor_layer := _layers[&"floor"] as TileMapLayer
	return to_global(floor_layer.map_to_local(local_cell))


func _world_to_local_cell(world_position: Vector2) -> Vector2i:
	var floor_layer := _layers[&"floor"] as TileMapLayer
	return floor_layer.local_to_map(to_local(world_position))


func _footprint_rect() -> Rect2i:
	return Rect2i(Vector2i.ZERO, definition.footprint_size)


func _anchor_world_cell() -> Vector2i:
	return Vector2i(
		int(round(global_position.x / float(cell_size))),
		int(round(global_position.y / float(cell_size)))
	)


func _is_footprint_cell(local_cell: Vector2i) -> bool:
	for footprint_cell in definition.get_floor_cells():
		if footprint_cell == local_cell:
			return true
	return false
