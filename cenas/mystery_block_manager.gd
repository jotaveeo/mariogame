class_name MysteryBlockManager
extends Node2D

signal coin_collected

const MYSTERY_BLOCK_SCENE = preload("res://cenas/mystery_block.tscn")
const POWER_UP_SCENE = preload("res://cenas/power_up.tscn")
const COIN_POPUP_SCENE = preload("res://cenas/coin_popup.tscn")
const MYSTERY_TILE_SOURCES = [11, 12, 13]
const EMPTY_BLOCK_SOURCE: int = 14
const BUMPABLE_TERRAIN_SOURCES = [1, 4]
const BREAKABLE_TERRAIN_SOURCES = [1, 4]
const ENEMY_HIT_HEIGHT: float = 10.0
const FRAGMENT_SCALE: Vector2 = Vector2(0.5, 0.5)

var terrain: TileMapLayer
var player: Player
var blocks: Dictionary[Vector2i, MysteryBlock] = {}
var animated_cells: Dictionary[Vector2i, bool] = {}

func setup(level_terrain: TileMapLayer, level_player: Player) -> void:
	terrain = level_terrain
	player = level_player
	player.mystery_block_hit.connect(_on_player_hit_block)
	for cell in terrain.get_used_cells():
		register_cell(cell)

func register_cell(cell: Vector2i) -> void:
	if blocks.has(cell):
		return
	var source_id = terrain.get_cell_source_id(cell)
	if not MYSTERY_TILE_SOURCES.has(source_id):
		return
	var tile_data = terrain.get_cell_tile_data(cell)
	if tile_data == null:
		return
	var reward = StringName(str(tile_data.get_custom_data("reward")))
	var block: MysteryBlock = MYSTERY_BLOCK_SCENE.instantiate()
	block.setup(terrain, cell, reward)
	block.activated.connect(_on_block_activated)
	add_child(block)
	block.global_position = terrain.to_global(terrain.map_to_local(cell))
	blocks[cell] = block

func _on_player_hit_block(hit_terrain: TileMapLayer, cell: Vector2i) -> void:
	if hit_terrain != terrain or animated_cells.has(cell):
		return
	if blocks.has(cell):
		var block = blocks[cell]
		if not block.used:
			_bounce_mushrooms_above(cell)
			block.bump()
		return
	var source_id = terrain.get_cell_source_id(cell)
	var atlas_coords = terrain.get_cell_atlas_coords(cell)
	var alternative_tile = terrain.get_cell_alternative_tile(cell)
	if player.player_mode == Player.PlayerMode.SMALL:
		if BUMPABLE_TERRAIN_SOURCES.has(source_id):
			_bounce_mushrooms_above(cell)
			_bump_terrain_block(cell, source_id, atlas_coords, alternative_tile)
	elif player.player_mode == Player.PlayerMode.BIG or player.player_mode == Player.PlayerMode.SHOOTING:
		if BREAKABLE_TERRAIN_SOURCES.has(source_id):
			_bounce_mushrooms_above(cell)
			_break_terrain_block(cell, source_id, atlas_coords)

func _bounce_mushrooms_above(cell: Vector2i) -> void:
	var block_center = terrain.to_global(terrain.map_to_local(cell))
	var tile_size = Vector2(terrain.tile_set.tile_size)
	for child in get_children():
		if (
			child is PowerUp
			and child.item_type == &"mushroom"
			and child.active
			and not child.collected
		):
			var distance_above = block_center.y - child.global_position.y
			if (
				absf(child.global_position.x - block_center.x) <= tile_size.x
				and distance_above > 0.0
				and distance_above <= tile_size.y + 8.0
			):
				child.bounce_and_reverse()

func _bump_terrain_block(cell: Vector2i, source_id: int, atlas_coords: Vector2i, alternative_tile: int) -> void:
	animated_cells[cell] = true
	_kill_enemies_above(cell)
	var bump = _create_tile_sprite(cell, source_id, atlas_coords)
	terrain.erase_cell(cell)
	var original_position = bump.position
	var tween = create_tween()
	tween.tween_property(bump, "position", original_position + Vector2(0, -4), 0.08)
	tween.tween_property(bump, "position", original_position, 0.08)
	tween.tween_callback(_restore_bumped_block.bind(cell, source_id, atlas_coords, alternative_tile, bump))

func _restore_bumped_block(cell: Vector2i, source_id: int, atlas_coords: Vector2i, alternative_tile: int, bump: Node2D) -> void:
	terrain.set_cell(cell, source_id, atlas_coords, alternative_tile)
	animated_cells.erase(cell)
	bump.queue_free()

func _break_terrain_block(cell: Vector2i, source_id: int, atlas_coords: Vector2i) -> void:
	animated_cells[cell] = true
	var fragments = Node2D.new()
	fragments.name = "TerrainFragments"
	fragments.z_index = 1
	add_child(fragments)
	fragments.global_position = terrain.to_global(terrain.map_to_local(cell))
	_kill_enemies_above(cell)
	var atlas = terrain.tile_set.get_source(source_id) as TileSetAtlasSource
	var texture_region = atlas.get_tile_texture_region(atlas_coords)
	for index in range(2):
		var sprite = Sprite2D.new()
		sprite.texture = atlas.get_texture()
		sprite.region_enabled = true
		sprite.region_rect = Rect2(Vector2(texture_region.position), Vector2(texture_region.size))
		sprite.scale = FRAGMENT_SCALE
		sprite.position = Vector2((index - 0.5) * terrain.tile_set.tile_size.x * FRAGMENT_SCALE.x, 0)
		fragments.add_child(sprite)
		var start = sprite.position
		var end = start + Vector2(-12 if index == 0 else 12, 8)
		var arc_height = 18.0
		create_tween().tween_method(
			_update_fragment.bind(sprite, start, end, arc_height),
			0.0,
			1.0,
			0.5
		)
	terrain.erase_cell(cell)
	var tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_callback(_finish_fragments.bind(cell, fragments))

func _update_fragment(progress: float, sprite: Sprite2D, start: Vector2, end: Vector2, arc_height: float) -> void:
	sprite.position = start.lerp(end, progress) + Vector2(0, -4.0 * arc_height * progress * (1.0 - progress))

func _finish_fragments(cell: Vector2i, fragments: Node2D) -> void:
	animated_cells.erase(cell)
	fragments.queue_free()

func _create_tile_sprite(cell: Vector2i, source_id: int, atlas_coords: Vector2i) -> Node2D:
	var atlas = terrain.tile_set.get_source(source_id) as TileSetAtlasSource
	var block = Node2D.new()
	block.z_index = 1
	add_child(block)
	block.global_position = terrain.to_global(terrain.map_to_local(cell))
	var sprite = Sprite2D.new()
	sprite.texture = atlas.get_texture()
	sprite.region_enabled = true
	var texture_region = atlas.get_tile_texture_region(atlas_coords)
	sprite.region_rect = Rect2(Vector2(texture_region.position), Vector2(texture_region.size))
	block.add_child(sprite)
	return block

func _kill_enemies_above(cell: Vector2i) -> void:
	var enemies = get_parent().get_node_or_null("Enemies")
	if enemies == null:
		return
	var block_center = terrain.to_global(terrain.map_to_local(cell))
	var half_width = terrain.tile_set.tile_size.x / 2.0
	var block_top = block_center.y - terrain.tile_set.tile_size.y / 2.0
	for enemy in enemies.get_children():
		if enemy is Enemy and not enemy.is_dead:
			var collider: CollisionShape2D = enemy.get_node("CollisionShape2D")
			if collider.disabled or collider.shape == null:
				continue
			# Use the feet and width of the actual collider, including shell offsets.
			var bounds: Rect2 = collider.global_transform * collider.shape.get_rect()
			var feet_gap = block_top - bounds.end.y
			var overlaps_block = bounds.end.x > block_center.x - half_width and bounds.position.x < block_center.x + half_width
			if overlaps_block and feet_gap >= -2.0 and feet_gap <= ENEMY_HIT_HEIGHT:
				enemy.die_from_hit()

func _on_block_activated(reward: StringName, world_position: Vector2, cell: Vector2i) -> void:
	blocks.erase(cell)
	if reward == &"coin":
		var popup: Node2D = COIN_POPUP_SCENE.instantiate()
		popup.position = to_local(world_position)
		popup.z_index = 2
		add_child(popup)
		coin_collected.emit()
		return
	var power_up: PowerUp = POWER_UP_SCENE.instantiate()
	power_up.setup(reward)
	power_up.position = to_local(world_position)
	power_up.z_index = 0
	add_child(power_up)
