extends CanvasLayer

@onready var mask: Control = $Mask


func _ready() -> void:
	visible = false


func set_active(active: bool, visible_world_tiles: Array[Vector2i] = [], tile_size: int = 16) -> void:
	visible = active
	mask.set_overlay(active, visible_world_tiles, tile_size)
