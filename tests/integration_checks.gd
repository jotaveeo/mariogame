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

func open_level(path: String, begin_game: bool = true) -> void:
	if is_instance_valid(level):
		root.remove_child(level)
		level.free()
	level = load(path).instantiate()
	root.add_child(level)
	current_scene = level
	await frames(30)
	if begin_game and not level.started:
		level.start_game()

func run_checks() -> void:
	await open_level("res://cenas/main.tscn", false)
	check(not level.started and get_tree().paused, "Main starts locked until Press Start is clicked")
	check(not level.hero.is_physics_processing(), "Player does not move before Press Start")
	check(level.hud.get_node("Message").text.contains("PRESS START"), "Start prompt is visible")
	var start_click = InputEventMouseButton.new()
	start_click.button_index = MOUSE_BUTTON_LEFT
	start_click.pressed = true
	var play_area: Area2D = level.get_node("PlayArea") as Area2D
	play_area.input_event.emit(level.get_viewport(), start_click, 0)
	check(level.started and not get_tree().paused, "Press Start click begins the game")
	await frames(30)
	check(level.time_limit == 60.0 and level.minimum_score == 2000, "Main rules remain one minute and 2000 points")
	check(level.hero.is_on_floor(), "Main spawn remains valid")
	check(level.next_level_path == "res://cenas/dungeon_level.tscn", "Dungeon follows the main level")
	level.hero.position.x = 700
	level._update_camera()
	var camera_x = level.camera.global_position.x
	var left_limit = level.hero.minimum_x
	level.hero.position.x = 100
	level._update_camera()
	check(level.camera.global_position.x == camera_x, "Camera never scrolls backward")
	level.hero._physics_process(0.0)
	check(level.hero.global_position.x >= left_limit, "Player cannot return beyond the left screen edge")
	check(level.hero.minimum_x < camera_x, "Player can still move left within the visible screen")
	await open_level("res://cenas/main.tscn")
	var manager = level.get_node("MysteryBlockManager")
	var cell = Vector2i(-6, -5)
	level.get_node("Terrain").set_cell(cell, 11, Vector2i.ZERO)
	manager.register_cell(cell)
	level.hero.mystery_block_hit.emit(level.get_node("Terrain"), cell)
	await frames(12)
	check(level.coins == 1 and level.score == 200, "Mystery block delivers coin reward")
	var terrain: TileMapLayer = level.get_node("Terrain")
	var terrain_cell = Vector2i(100, 100)
	terrain.set_cell(terrain_cell, 1, Vector2i.ZERO)
	var mushroom: PowerUp = load("res://cenas/power_up.tscn").instantiate()
	mushroom.setup(&"mushroom")
	mushroom.position = terrain.to_global(terrain.map_to_local(terrain_cell)) + Vector2(0, -16)
	manager.add_child(mushroom)
	mushroom.set_physics_process(false)
	mushroom._activate()
	var enemy = level.enemies[0]
	enemy.set_physics_process(false)
	enemy.global_position = terrain.to_global(terrain.map_to_local(terrain_cell)) + Vector2(0, -16)
	level.hero.mystery_block_hit.emit(terrain, terrain_cell)
	check(enemy.is_dead, "Small Mario's terrain block bump kills an enemy above it")
	check(mushroom.direction == -1.0 and mushroom.velocity.y < 0.0, "Bumping a block below a mushroom reverses and bounces it")
	mushroom.queue_free()
	await frames(12)
	check(terrain.get_cell_source_id(terrain_cell) == 1, "Small Mario's terrain bump restores the block")
	var too_high_enemy = level.enemies[1]
	too_high_enemy.set_physics_process(false)
	var high_enemy_check_cell = Vector2i(100, 101)
	too_high_enemy.global_position = terrain.to_global(terrain.map_to_local(high_enemy_check_cell)) + Vector2(0, -39)
	terrain.set_cell(high_enemy_check_cell, 1, Vector2i.ZERO)
	level.hero.mystery_block_hit.emit(terrain, high_enemy_check_cell)
	check(not too_high_enemy.is_dead, "Terrain bump does not kill enemies more than 30 pixels above the block")
	var dungeon_brick_cell = Vector2i(100, 102)
	terrain.set_cell(dungeon_brick_cell, 4, Vector2i.ZERO)
	level.hero.mystery_block_hit.emit(terrain, dungeon_brick_cell)
	await frames(12)
	check(terrain.get_cell_source_id(dungeon_brick_cell) == 4, "Small Mario can bump Brick1 dungeon terrain")
	var hard_block_cell = Vector2i(101, 100)
	terrain.set_cell(hard_block_cell, 2, Vector2i.ZERO)
	level.hero.mystery_block_hit.emit(terrain, hard_block_cell)
	check(terrain.get_cell_source_id(hard_block_cell) == 2, "Small Mario does not bump HardBlock terrain")
	var brick_two_cell = Vector2i(102, 100)
	terrain.set_cell(brick_two_cell, 5, Vector2i.ZERO)
	level.hero.mystery_block_hit.emit(terrain, brick_two_cell)
	check(terrain.get_cell_source_id(brick_two_cell) == 5, "Small Mario does not bump Brick2 dungeon terrain")
	var break_cell = Vector2i(101, 100)
	terrain.set_cell(break_cell, 1, Vector2i.ZERO)
	mushroom = load("res://cenas/power_up.tscn").instantiate()
	mushroom.setup(&"mushroom")
	mushroom.position = terrain.to_global(terrain.map_to_local(break_cell)) + Vector2(0, -16)
	manager.add_child(mushroom)
	mushroom.set_physics_process(false)
	mushroom._activate()
	level.hero.player_mode = Player.PlayerMode.BIG
	var big_mode_enemy = level.enemies[2]
	big_mode_enemy.set_physics_process(false)
	big_mode_enemy.global_position = terrain.to_global(terrain.map_to_local(break_cell)) + Vector2(0, -16)
	level.hero.mystery_block_hit.emit(terrain, break_cell)
	check(terrain.get_cell_source_id(break_cell) == -1, "Big Mario breaks a terrain block")
	check(mushroom.direction == -1.0 and mushroom.velocity.y < 0.0, "Breaking a block below a mushroom reverses and bounces it")
	mushroom.queue_free()
	check(big_mode_enemy.is_dead, "Big Mario's block break kills an enemy above it")
	var fragments = manager.get_node_or_null("TerrainFragments")
	check(is_instance_valid(fragments) and fragments.get_child_count() == 2, "Breaking a terrain block creates two fragments")
	var fragment_one: Sprite2D = fragments.get_child(0)
	var fragment_two: Sprite2D = fragments.get_child(1)
	check(fragment_one.region_rect == fragment_two.region_rect, "Both fragments use the full sprite of the broken block")
	check(fragment_one.scale == Vector2(0.5, 0.5) and fragment_two.scale == Vector2(0.5, 0.5), "Broken block fragments are scaled down")
	var hard_break_cell = Vector2i(103, 100)
	terrain.set_cell(hard_break_cell, 2, Vector2i.ZERO)
	level.hero.mystery_block_hit.emit(terrain, hard_break_cell)
	check(terrain.get_cell_source_id(hard_break_cell) == 2, "Big Mario does not break HardBlock terrain")
	var brick_two_break_cell = Vector2i(104, 100)
	terrain.set_cell(brick_two_break_cell, 5, Vector2i.ZERO)
	level.hero.mystery_block_hit.emit(terrain, brick_two_break_cell)
	check(terrain.get_cell_source_id(brick_two_break_cell) == 5, "Big Mario does not break Brick2 dungeon terrain")
	var shooting_cell = Vector2i(102, 100)
	terrain.set_cell(shooting_cell, 1, Vector2i.ZERO)
	level.hero.player_mode = Player.PlayerMode.SHOOTING
	var shooting_enemy = level.enemies[3]
	shooting_enemy.set_physics_process(false)
	shooting_enemy.global_position = terrain.to_global(terrain.map_to_local(shooting_cell)) + Vector2(0, -16)
	level.hero.mystery_block_hit.emit(terrain, shooting_cell)
	check(terrain.get_cell_source_id(shooting_cell) == -1, "Shooting Mario breaks a terrain block")
	check(shooting_enemy.is_dead, "Shooting Mario's block break kills an enemy above it")
	await frames(32)
	check(manager.get_node_or_null("TerrainFragments") == null, "Terrain fragments disappear after their animation")
	level.hero.player_mode = Player.PlayerMode.SMALL
	level.hero.apply_powerup(&"mushroom")
	var flower = load("res://cenas/power_up.tscn").instantiate()
	flower.setup(&"flower")
	flower.position = level.hero.position + Vector2(0, 16)
	level.add_child(flower)
	flower._on_pickup_area_body_entered(level.hero)
	check(not flower.is_queued_for_deletion(), "Rejected pickup survives transformation")
	await frames(75)
	check(level.hero.player_mode == Player.PlayerMode.SHOOTING, "Overlapping flower is collected after transformation")
	check(not is_instance_valid(flower), "Accepted flower is removed")
	await frames(65)
	level.hero._shoot_fireball()
	var projectile = level.get_node_or_null("Fireball")
	check(is_instance_valid(projectile), "Shooting creates projectile")
	await frames(190)
	check(not is_instance_valid(projectile), "Projectile cleans itself up safely")
	level.score = level.minimum_score
	level._finish(level.hero)
	check(level.hud.get_node("Message").text.contains("ENTER: próxima fase") and level.hud.get_node("Message").text.contains("ESC: Menu"), "Main completion offers next phase and menu")
	var accept_event = InputEventAction.new()
	accept_event.action = "ui_accept"
	accept_event.pressed = true
	level._unhandled_input(accept_event)
	await frames(5)
	level = current_scene
	check(level.scene_file_path == "res://cenas/dungeon_level.tscn", "Enter advances to dungeon after main completion")
	await frames(30)
	check(level.hero.is_on_floor() and not level.hero.is_dead, "Dungeon has safe spawn")
	check(level.time_limit == 120.0 and level.time_left <= 120.0 and level.time_left > 0.0, "Dungeon timer starts at two minutes")
	level.hud.update_stats(level.score, level.coins, 120.0, level.minimum_score)
	check(level.hud.get_node("Score").text.contains("02:00"), "HUD displays dungeon time as two minutes")
	var initial_feet = level.hero.global_position.y + 8.0
	level.hero.apply_powerup(&"mushroom")
	for index in range(70):
		await frames(1)
		var sprite = level.hero.animated_sprite_2d
		var texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		var sprite_feet = sprite.global_position.y + texture.get_height() / 2.0
		var shape = level.hero.body_collision_shape
		var physical_feet = shape.global_position.y + shape.shape.size.y / 2.0
		check(absf(sprite_feet - physical_feet) < 0.1, "Sprite and physical feet remain aligned during transformation")
	check(level.hero.is_on_floor(), "Big Mario stays on the dungeon floor")
	check(absf(level.hero.global_position.y + 8.0 - initial_feet) < 0.1, "Growing does not move feet into terrain")
	check(level.hero.body_collision_shape.shape.size.y == 32, "Big collider matches 32 pixel sprite")
	check(level.time_limit == 120 and level.minimum_score == 2000, "Dungeon uses two-minute timer and shared score rules")
	check(level.get_node("Finish/Goal").body_entered.get_connections().size() > 0, "Dungeon goal is connected")
	level.score = 1999
	level._finish(level.hero)
	check(not level.finished, "Dungeon enforces minimum score")
	level.score = 2000
	level._finish(level.hero)
	check(level.finished, "Dungeon can be completed")
	check(level.hud.get_node("Message").text.contains("FASE CONCLUÍDA"), "Dungeon completion shows HUD")
	check(level.hud.get_node("Message").text.contains("R:") and level.hud.get_node("Message").text.contains("ESC: Menu"), "Dungeon completion offers restart and menu")
	var restart_event = InputEventAction.new()
	restart_event.action = "restart"
	restart_event.pressed = true
	level._unhandled_input(restart_event)
	await frames(5)
	level = current_scene
	check(level.scene_file_path == "res://cenas/dungeon_level.tscn" and not level.finished, "R restarts the completed dungeon")
	level.score = level.minimum_score
	level._finish(level.hero)
	var menu_event = InputEventAction.new()
	menu_event.action = "ui_cancel"
	menu_event.pressed = true
	level._unhandled_input(menu_event)
	await frames(5)
	level = current_scene
	check(level.scene_file_path == "res://cenas/main.tscn" and not level.started, "Dungeon menu returns to the locked main screen")
	print("Integration checks completed; failures: ", failures)
	quit(1 if failures else 0)
