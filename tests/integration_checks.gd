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

func open_level(path: String) -> void:
	if is_instance_valid(level):
		root.remove_child(level)
		level.free()
	level = load(path).instantiate()
	root.add_child(level)
	current_scene = level
	await frames(30)

func run_checks() -> void:
	await open_level("res://cenas/main.tscn")
	check(level.time_limit == 60.0 and level.minimum_score == 2000, "Main rules remain one minute and 2000 points")
	check(level.hero.is_on_floor(), "Main spawn remains valid")
	check(level.next_level_path == "res://cenas/dungeon_level.tscn", "Dungeon follows the main level")
	check(level.hero.minimum_x == -INF, "Player can return for missed points")
	var manager = level.get_node("MysteryBlockManager")
	var cell = Vector2i(-6, -5)
	level.get_node("Terrain").set_cell(cell, 11, Vector2i.ZERO)
	manager.register_cell(cell)
	level.hero.mystery_block_hit.emit(level.get_node("Terrain"), cell)
	await frames(12)
	check(level.coins == 1 and level.score == 200, "Mystery block delivers coin reward")
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
	var accept_event = InputEventAction.new()
	accept_event.action = "ui_accept"
	accept_event.pressed = true
	level._unhandled_input(accept_event)
	await frames(5)
	level = current_scene
	check(level.scene_file_path == "res://cenas/dungeon_level.tscn", "Enter advances to dungeon after main completion")
	await frames(30)
	check(level.hero.is_on_floor() and not level.hero.is_dead, "Dungeon has safe spawn")
	check(level.time_limit == 60 and level.minimum_score == 2000, "Dungeon uses shared rules")
	check(level.get_node("Finish/Goal").body_entered.get_connections().size() > 0, "Dungeon goal is connected")
	level.score = 1999
	level._finish(level.hero)
	check(not level.finished, "Dungeon enforces minimum score")
	level.score = 2000
	level._finish(level.hero)
	check(level.finished, "Dungeon can be completed")
	check(level.hud.get_node("Message").text.contains("FASE CONCLUÍDA"), "Dungeon completion shows HUD")
	print("Integration checks completed; failures: ", failures)
	quit(1 if failures else 0)
