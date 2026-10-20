extends SceneTree

var level: Node2D
var failures: int = 0

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

func fresh_level() -> void:
	if is_instance_valid(level):
		root.remove_child(level)
		level.free()
	level = load("res://cenas/main.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await frames(3)

func run_checks() -> void:
	await fresh_level()
	await frames(30)
	check(level.hero.is_on_floor(), "Player spawn has solid ground")
	check(level.get_node("Terrain") is TileMapLayer, "Terrain uses TileMapLayer")
	check(not level.get_node("Terrain").get_used_cells().is_empty(), "Terrain contains painted tiles")
	check(level.enemies.size() == 12, "All twelve enemies are preserved")
	check(InputMap.has_action("restart"), "Restart is mapped as an action")
	var coin = level.get_node("Coins").get_child(0)
	check(coin.scene_file_path == "res://cenas/coin.tscn", "Coins use a reusable scene")
	var coin_sprite: AnimatedSprite2D = coin.get_node("AnimatedSprite2D")
	check(coin_sprite.sprite_frames.get_frame_count("default") == 6, "Coin animation uses all six frames")
	check(coin_sprite.sprite_frames.get_animation_speed("default") == 6.0 and coin_sprite.sprite_frames.get_animation_loop("default") and coin_sprite.autoplay == "default" and coin_sprite.is_playing(), "Coin animation loops automatically once per second")
	check(level.hud.scene_file_path == "res://cenas/hud.tscn", "HUD uses a reusable scene")
	check(level.hero.minimum_x == level.camera_progress_x - level.camera_half_width + 14.0, "Camera recoil margin is fourteen pixels")
	var terrain: TileMapLayer = level.get_node("Terrain")
	var tile_set: TileSet = terrain.tile_set
	var coin_block_source = tile_set.get_source(11) as TileSetAtlasSource
	var mushroom_block_source = tile_set.get_source(12) as TileSetAtlasSource
	var flower_block_source = tile_set.get_source(13) as TileSetAtlasSource
	check(coin_block_source.get_tile_data(Vector2i.ZERO, 0).get_custom_data("reward") == "coin", "Mystery block source 11 gives a coin")
	check(mushroom_block_source.get_tile_data(Vector2i.ZERO, 0).get_custom_data("reward") == "mushroom", "Mystery block source 12 gives a mushroom")
	check(flower_block_source.get_tile_data(Vector2i.ZERO, 0).get_custom_data("reward") == "flower", "Mystery block source 13 gives a flower")
	var mystery_scene = load("res://cenas/mystery_block.tscn").instantiate()
	var mystery_frames: SpriteFrames = mystery_scene.get_node("AnimatedSprite2D").sprite_frames
	check(mystery_frames.get_frame_count("default") == 3 and mystery_frames.get_animation_loop("default") and mystery_scene.get_node("AnimatedSprite2D").autoplay == "default", "Mystery block animation uses three looping autoplay frames")
	check(mystery_frames.get_frame_texture("default", 2).resource_path.ends_with("MysterBox2.png"), "Mystery block animation ends with MysterBox2.png")
	mystery_scene.free()
	var mystery_manager = level.get_node("MysteryBlockManager") as MysteryBlockManager
	var original_hero_position = level.hero.global_position
	var original_camera_progress = level.camera_progress_x
	var test_block_cell = Vector2i(-5, -5)
	terrain.set_cell(test_block_cell, 13, Vector2i.ZERO)
	mystery_manager.register_cell(test_block_cell)
	level.hero.mystery_block_hit.emit(terrain, test_block_cell)
	check(mystery_manager.blocks[test_block_cell].used, "Player head contact activates an unused mystery block")
	await frames(12)
	check(terrain.get_cell_source_id(test_block_cell) == 14, "Used mystery block changes to EmptyBlock")
	var flower = mystery_manager.get_node("PowerUp") as PowerUp
	flower._on_pickup_area_body_entered(level.hero)
	check(level.hero.player_mode == Player.PlayerMode.SHOOTING, "Flower reward activates shooting form")
	level.hero.animated_sprite_2d.scale.x = -1.0
	level.hero._shoot_fireball()
	var fireball = level.get_node("Fireball")
	check(fireball.direction == -1.0, "Fireball launches in Mario's facing direction")
	check(fireball.get_node("AnimatedSprite2D").sprite_frames.get_frame_count("default") == 3, "Fireball animates with three frames")
	level.camera_progress_x = 500.0
	level.camera.global_position.x = level.camera_progress_x
	level.hero.global_position.x = 100.0
	level._physics_process(0.0)
	check(level.camera_progress_x == 500.0, "Main camera does not move back into explored scenery")
	level.camera_progress_x = original_camera_progress
	level.camera.global_position.x = original_camera_progress
	level.hero.global_position = original_hero_position
	level.hero.minimum_x = original_camera_progress - level.camera_half_width + 14.0
	level.hero.take_damage()
	check(level.hero.player_mode == Player.PlayerMode.BIG and not level.hero.is_dead, "First damage removes fire power without killing Mario")
	level.hero.damage_invulnerability = 0.0
	level.hero.take_damage()
	check(level.hero.player_mode == Player.PlayerMode.SMALL and not level.hero.is_dead, "Second damage returns Mario to small form")
	fireball.queue_free()
	var mushroom_cell = Vector2i(-7, -5)
	terrain.set_cell(mushroom_cell, 12, Vector2i.ZERO)
	mystery_manager.register_cell(mushroom_cell)
	level.hero.mystery_block_hit.emit(terrain, mushroom_cell)
	await frames(12)
	var mushroom = mystery_manager.get_node("PowerUp") as PowerUp
	check(mushroom.get_node("Sprite2D").texture.resource_path.ends_with("MagicMushroom.png"), "Mushroom reward uses MagicMushroom.png")
	mushroom._on_pickup_area_body_entered(level.hero)
	check(level.hero.player_mode == Player.PlayerMode.BIG and (level.hero.body_collision_shape.shape as RectangleShape2D).size.y == 24.0, "Mushroom activates adult form and enlarges the collision shape")
	level.hero.damage_invulnerability = 0.0
	level.hero.take_damage()
	check(level.hero.player_mode == Player.PlayerMode.SMALL, "Damage removes the mushroom power")
	coin._on_body_entered(level.hero)
	coin._on_body_entered(level.hero)
	check(level.coins == 1 and level.score == 200, "Coin awards points only once")
	var test_coin_cell = Vector2i(-6, -5)
	terrain.set_cell(test_coin_cell, 11, Vector2i.ZERO)
	mystery_manager.register_cell(test_coin_cell)
	level.hero.mystery_block_hit.emit(terrain, test_coin_cell)
	await frames(12)
	check(level.coins == 2 and level.score == 400, "Mystery block coin awards 200 points and increments the coin count")
	var coin_popup = mystery_manager.get_node("CoinPopup")
	check(coin_popup.get_node("Sprite2D").texture.resource_path.ends_with("Coin2.png"), "Mystery block coin uses Coin2.png")
	# Exercise actual overlap signals rather than only calling the collision handler.
	var goomba = level.enemies[0]
	goomba.set_physics_process(false)
	level.hero.position = goomba.position + Vector2(0, -32)
	level.hero.velocity = Vector2(0, 100)
	await frames(12)
	check(goomba.is_dead, "Descending player stomps Goomba through its hitbox")
	check(not level.hero.is_dead, "Stomp does not kill player")
	check(level.score >= 300, "Stomp awards points through level signal")
	await fresh_level()
	var koopa = level.enemies[8] as Koopa
	check(not koopa.animated_sprite_2d.flip_h, "Koopa faces its initial walking direction")
	koopa.horizontal_speed *= -1
	koopa._on_direction_changed()
	check(koopa.animated_sprite_2d.flip_h, "Koopa flips to face its reversed walking direction")
	koopa.die()
	await frames(2)
	check(koopa.in_a_shell and not koopa.is_dead, "First stomp creates a live shell")
	level.hero.position = koopa.position + Vector2(-20, 0)
	level.hero.velocity = Vector2.ZERO
	level.hero.handle_enemy_collision(koopa)
	check(koopa.horizontal_speed < 0, "Side contact kicks stopped shell away")
	level.hero.position = koopa.position + Vector2(0, -24)
	level.hero.velocity = Vector2(0, 100)
	level.hero.handle_enemy_collision(koopa)
	check(koopa.horizontal_speed == 0, "Descending stomp stops moving shell")
	check(level.hero.velocity.y < 0, "Shell stomp bounces player")
	koopa.on_stomp(koopa.position - Vector2(20, 0))
	level.hero.position = koopa.position - Vector2(20, 0)
	level.hero.velocity = Vector2.ZERO
	level.hero.handle_enemy_collision(koopa)
	check(level.hero.is_dead, "Moving shell damages player from side")
	await fresh_level()
	# Check a shell actually eliminates another enemy via Area2D overlap.
	koopa = level.enemies[8] as Koopa
	goomba = level.enemies[0]
	goomba.set_physics_process(false)
	koopa.position = goomba.position + Vector2(48, -4)
	koopa.die()
	koopa.on_stomp(koopa.position + Vector2(20, 0))
	koopa.set_physics_process(true)
	await frames(24)
	check(goomba.is_dead, "Moving shell kills enemy through real overlap")
	check(level.score == 100, "Shell kill awards points through signal")
	await fresh_level()
	# Timeout and falling both trigger the normal death sequence.
	level.time_left = 0.001
	await frames(3)
	check(level.hero.is_dead, "Timeout kills player")
	check(level.time_left == 0.0, "Timer stops at zero")
	check(level.hud.get_node("Message").text.contains("TEMPO ESGOTADO"), "Timeout displays explanation")
	check(level.hud.get_node("Score").text.contains("00:00"), "Timer displays minutes and seconds")
	await fresh_level()
	level.hero.position = Vector2(620, 320)
	await frames(3)
	check(level.hero.is_dead, "Falling past the level limit kills player")
	await fresh_level()
	level.hero.position = Vector2(8, 196)
	Input.action_press("left")
	await frames(40)
	Input.action_release("left")
	check(level.hero.position.x >= 5.9, "Physical boundary keeps player inside level")
	await fresh_level()
	level.score = level.minimum_score - 100
	var old_score = level.score
	level._finish(level.hero)
	check(not level.finished, "Goal rejects insufficient score before awarding completion bonus")
	check(level.score == old_score, "Rejected finish does not award bonus")
	check(level.hero.is_physics_processing(), "Player can continue collecting points")
	check(level.hud.get_node("Message").text.contains("100 PONTOS"), "Goal explains missing points")
	level.score = level.minimum_score
	level._finish(level.hero)
	check(level.finished, "Exact minimum score allows completion")
	check(level.score > level.minimum_score, "Completion bonus is awarded after eligibility")
	await check_traversal()
	print("Checks completed; failures: ", failures)
	quit(1 if failures else 0)

func check_traversal() -> void:
	await fresh_level()
	# Isolate terrain reachability; combat and score gate are checked separately.
	level.score = level.minimum_score
	for enemy in level.enemies:
		enemy.disable_interactions()
	Input.action_press("right")
	var jump_was_pressed = false
	for index in range(2400):
		if level.finished or level.hero.is_dead:
			break
		var hero = level.hero
		var space = hero.get_world_2d().direct_space_state
		var start = hero.global_position + Vector2(24, 8)
		var probe = PhysicsRayQueryParameters2D.create(start, start + Vector2(0, 20), 2)
		var needs_jump = hero.is_on_floor() and (hero.is_on_wall() or space.intersect_ray(probe).is_empty())
		if needs_jump and not jump_was_pressed:
			Input.action_press("jump")
			jump_was_pressed = true
		elif jump_was_pressed and hero.velocity.y >= 0:
			Input.action_release("jump")
			jump_was_pressed = false
		await frames(1)
	Input.action_release("right")
	Input.action_release("jump")
	check(level.finished, "Automatic traversal crosses gaps and staircase and reaches goal (x=%s)" % level.hero.position.x)
	if level.finished:
		check(not level.hero.is_physics_processing(), "Completion stops player")
		check(level.hud.get_node("Message").text.contains("FASE CONCLUÍDA"), "HUD displays completion")
