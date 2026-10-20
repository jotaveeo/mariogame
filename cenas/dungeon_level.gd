extends GameLevel

@export var fall_margin: float = 64.0

func _configure_level() -> void:
	var terrain: TileMapLayer = $Terrain
	var used_rect = terrain.get_used_rect()
	if used_rect.has_area():
		var last_tile = used_rect.end - Vector2i.ONE
		var map_end = terrain.to_global(terrain.map_to_local(last_tile)) + Vector2(terrain.tile_set.tile_size) / 2.0
		level_width = ceili(map_end.x)
		fall_limit = map_end.y + fall_margin
