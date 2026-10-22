extends SceneTree

var failures: int = 0
var level: GameLevel
var heard: Array[StringName] = []

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

func open_level(path: String = "res://cenas/main.tscn") -> void:
	if is_instance_valid(level):
		root.remove_child(level)
		level.free()
	paused = false
	level = load(path).instantiate()
	root.add_child(level)
	current_scene = level
	level.audio.sound_played.connect(func(sound: StringName): heard.append(sound))
	heard.clear()

func run_checks() -> void:
	await open_level()
	check(level.get_node("Audio") == level.audio, "Audio is instantiated directly in the level scene")
	check(level.audio.get_node("Effects/coin").stream != null, "Coin WAV is bound directly to its AudioStreamPlayer")
	check(level.audio.streams.size() == 16, "All sixteen downloaded WAV files load")
	for stream in level.audio.streams.values():
		check(stream.get_length() > 0, "Imported audio has positive duration")
		var playback = stream.instantiate_playback()
		playback.start()
		var peak: float = 0.0
		for block in range(16):
			for sample in playback.mix_audio(1.0, 2048):
				peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
		playback.stop()
		check(peak > 0.01, "Decoded audio has audible signal: %s (peak=%s)" % [stream.resource_path, peak])
	await frames(10)
	check(heard.is_empty() and not level.audio.is_jingle_playing(), "Menu starts silent")
	level.start_game()
	await frames(30)
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	check(&"jump_small" in heard, "Small jump triggers audio")
	await frames(50)
	level._collect_coin()
	check(heard.back() == &"coin", "Coin triggers audio")
	check(level.audio.effect_players[&"coin"].playing, "Coin event actually starts its AudioStreamPlayer")
	var manager = level.get_node("MysteryBlockManager")
	var terrain: TileMapLayer = level.get_node("Terrain")
	var cell = Vector2i(80, 6)
	terrain.set_cell(cell, 1, Vector2i.ZERO)
	level.hero.mystery_block_hit.emit(terrain, cell)
	check(heard.back() == &"bump", "Small head bump triggers audio")
	await frames(12)
	level.hero.player_mode = Player.PlayerMode.BIG
	level.hero.mystery_block_hit.emit(terrain, cell)
	check(heard.back() == &"brick_break", "Brick break triggers audio")
	level.hero.player_mode = Player.PlayerMode.SMALL
	level.hero.transformation_time_left = 0
	level.hero.apply_powerup(&"mushroom")
	check(heard.back() == &"power_up", "Collecting mushroom triggers power-up audio")
	var reward_cell = Vector2i(81, 6)
	terrain.set_cell(reward_cell, 13, Vector2i.ZERO)
	manager.register_cell(reward_cell)
	level.hero.mystery_block_hit.emit(terrain, reward_cell)
	await frames(12)
	check(&"power_up_appears" in heard, "Emerging flower triggers its own sound")
	level.hero.transformation_time_left = 0
	level.hero.apply_powerup(&"flower")
	check(heard.back() == &"power_up", "Collecting flower triggers power-up audio")
	level.hero.transformation_time_left = 0
	level.hero.take_damage()
	check(heard.back() == &"power_down", "Losing power triggers audio")
	level.hero.player_mode = Player.PlayerMode.SHOOTING
	level.hero.transformation_time_left = 0
	level.hero._shoot_fireball()
	check(heard.back() == &"fireball", "Shooting triggers audio")
	level.enemies[8].on_stomp(level.enemies[8].global_position - Vector2(20, 0))
	check(heard.back() == &"kick", "Shell kick triggers audio")
	level.hero.player_mode = Player.PlayerMode.SMALL
	level.hero.damage_invulnerability = 0
	var goomba = level.enemies[0]
	level.hero.global_position = goomba.global_position - Vector2(0, 24)
	level.hero.velocity = Vector2(0, 100)
	level.hero.handle_enemy_collision(goomba)
	check(heard.back() == &"stomp", "Stomping triggers audio")
	level.time_left = 20.01
	level._physics_process(0.02)
	level._physics_process(0.02)
	check(heard.count(&"warning") == 1, "Time warning plays only once")
	level.hero.die()
	check(heard.back() == &"death", "Normal death plays Mario dies")
	check(level.audio.jingle.stream == level.audio.streams[&"death"], "Death replaces warning")
	# Exercise the end-of-animation handler while a jingle is still playing.
	level._on_death_finished()
	check(current_scene == level, "Death handler waits for its jingle to finish")
	await level.audio.jingle_finished
	await frames(3)
	level = current_scene
	check(not level.started, "Finished death jingle returns to start menu")
	await open_level()
	level.start_game()
	level.time_left = 0.001
	level._physics_process(0.02)
	check(heard.back() == &"game_over", "Timeout uses Game Over instead of overlapping death clips")
	await level.audio.jingle_finished
	await frames(3)
	level = current_scene
	await open_level()
	level.start_game()
	level.score = level.minimum_score
	level._finish(level.hero)
	check(heard.back() == &"stage_clear", "First stage completion plays Stage clear")
	await level.audio.jingle_finished
	await frames(3)
	await open_level("res://cenas/dungeon_level.tscn")
	level.score = level.minimum_score
	level._finish(level.hero)
	check(heard.back() == &"world_clear", "Final stage completion plays World clear")
	await level.audio.jingle_finished
	await frames(3)
	print("Audio checks completed; failures: ", failures)
	level.audio.stop_all()
	root.remove_child(level)
	level.free()
	await frames(3)
	quit(1 if failures else 0)
