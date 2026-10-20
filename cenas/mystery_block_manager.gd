class_name MysteryBlockManager
extends Node

signal coin_collected

const MYSTERY_BLOCK_SCENE = preload("res://cenas/mystery_block.tscn")
const POWER_UP_SCENE = preload("res://cenas/power_up.tscn")
const COIN_POPUP_SCENE = preload("res://cenas/coin_popup.tscn")
const MYSTERY_TILE_SOURCES = [11, 12, 13]
const EMPTY_BLOCK_SOURCE: int = 14

var terrain: TileMapLayer
var player: Player
var blocks: Dictionary[Vector2i, MysteryBlock] = {}

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
	if hit_terrain != terrain or not blocks.has(cell):
		return
	blocks[cell].bump()

func _on_block_activated(reward: StringName, world_position: Vector2, cell: Vector2i) -> void:
	blocks.erase(cell)
	if reward == &"coin":
		var popup: Node2D = COIN_POPUP_SCENE.instantiate()
		add_child(popup)
		popup.global_position = world_position
		coin_collected.emit()
		return
	var power_up: PowerUp = POWER_UP_SCENE.instantiate()
	power_up.setup(reward)
	add_child(power_up)
	power_up.global_position = world_position
