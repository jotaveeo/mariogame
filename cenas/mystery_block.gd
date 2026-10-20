class_name MysteryBlock
extends Node2D

signal activated(reward: StringName, world_position: Vector2, cell: Vector2i)

const EMPTY_BLOCK_SOURCE: int = 14

var terrain: TileMapLayer
var cell: Vector2i
var reward: StringName
var used: bool = false

func setup(tilemap: TileMapLayer, tile_cell: Vector2i, item_reward: StringName) -> void:
	terrain = tilemap
	cell = tile_cell
	reward = item_reward

func bump() -> void:
	if used:
		return
	used = true
	var original_position = position
	var tween = create_tween()
	tween.tween_property(self, "position", original_position + Vector2(0, -4), 0.08)
	tween.tween_property(self, "position", original_position, 0.08)
	tween.tween_callback(_finish_bump)

func _finish_bump() -> void:
	terrain.set_cell(cell, EMPTY_BLOCK_SOURCE, Vector2i.ZERO)
	activated.emit(reward, global_position, cell)
	queue_free()
