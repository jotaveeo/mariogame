extends SceneTree

var failures: int = 0
var level: GameLevel

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
		await process_frame

func create_enemy(kind: String, block_top: Vector2, offset: Vector2) -> Enemy:
	var scene = load("res://cenas/goomba.tscn" if kind == "goomba" else "res://cenas/koopa.tscn")
	var enemy: Enemy = scene.instantiate()
	level.get_node("Enemies").add_child(enemy)
	enemy.set_physics_process(false)
	if kind == "shell":
		enemy.die()
	await frames(2)
	var collider: CollisionShape2D = enemy.get_node("CollisionShape2D")
	var bounds: Rect2 = collider.global_transform * collider.shape.get_rect()
	enemy.global_position += block_top + offset - Vector2(bounds.get_center().x, bounds.end.y)
	return enemy

func run_checks() -> void:
	level = load("res://cenas/main.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	level.start_game()
	await frames(3)
	var terrain: TileMapLayer = level.get_node("Terrain")
	var manager = level.get_node("MysteryBlockManager")
	var cell = Vector2i(80, 6)
	var block_top = terrain.to_global(terrain.map_to_local(cell)) - Vector2(0, 8)
	for mode in [Player.PlayerMode.SMALL, Player.PlayerMode.BIG]:
		level.hero.player_mode = mode
		for source in [1, 4]:
			for kind in ["goomba", "koopa", "shell"]:
				terrain.set_cell(cell, source, Vector2i.ZERO)
				var enemy = await create_enemy(kind, block_top, Vector2.ZERO)
				level.hero.mystery_block_hit.emit(terrain, cell)
				check(enemy.is_dead, "%s on source %d is hit by player mode %d" % [kind, source, mode])
				await frames(35)
				if is_instance_valid(enemy):
					enemy.queue_free()
			# Nearby enemies must not be hit unless they overlap the top of the block.
			for offset in [Vector2(0, -24), Vector2(40, 0)]:
				terrain.set_cell(cell, source, Vector2i.ZERO)
				var enemy = await create_enemy("koopa", block_top, offset)
				level.hero.mystery_block_hit.emit(terrain, cell)
				check(not enemy.is_dead, "Enemy at offset %s is outside block hit area" % offset)
				enemy.queue_free()
				await frames(35)
	print("Block contact checks completed; failures: ", failures)
	quit(1 if failures else 0)
