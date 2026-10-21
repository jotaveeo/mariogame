extends SceneTree

var level: GameLevel
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

func fresh_level(begin_game: bool = true) -> void:
	if is_instance_valid(level):
		root.remove_child(level)
		level.free()
	level = load("res://cenas/main.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await frames(3)
	if begin_game:
		level.start_game()

func run_checks() -> void:
	await fresh_level(false)
	check(not level.started and get_tree().paused, "Main waits for the Press Start click")
	check(not level.hero.is_physics_processing(), "Player stays still before starting")
	check(level.hud.get_node("Message").text.contains("PRESS START"), "Start prompt is visible")
	level.start_game()
	check(level.started and not get_tree().paused, "Starting the game resumes the scene")
	await frames(30)
	check(level.hero.is_on_floor(), "Player spawn has solid ground")
	check(level.get_node("Terrain") is TileMapLayer, "Terrain uses TileMapLayer")
	check(not level.get_node("Terrain").get_used_cells().is_empty(), "Terrain contains painted tiles")
	check(level.enemies.size() == 12, "All twelve enemies are preserved")
	check(InputMap.has_action("restart"), "Restart is mapped as an action")
	var coin = level.get_node("Coins").get_child(0)
	check(coin.scene_file_path == "res://cenas/coin.tscn", "Coins use a reusable scene")
	check(level.hud.scene_file_path == "res://cenas/hud.tscn", "HUD uses a reusable scene")
	coin._on_body_entered(level.hero)
	coin._on_body_entered(level.hero)
	check(level.coins == 1 and level.score == 200, "Coin awards points only once")
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
