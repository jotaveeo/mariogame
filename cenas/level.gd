class_name GameLevel
extends Node2D

const AUDIO_SCENE = preload("res://cenas/level_audio.tscn")
const POINTS_LABEL_SCENE = preload("res://cenas/points_label.tscn")

@export_file("*.tscn") var next_level_path: String = ""
@export var start_locked: bool = false
@export var level_width: int = 3520
@export_range(1.0, 3600.0, 1.0) var time_limit: float = 60.0
@export_range(0, 100000, 100) var minimum_score: int = 2000
@export var fall_limit: float = 300.0
@export var activation_distance: float = 220.0
@export var camera_lookahead: float = 48.0
@export_range(6.0, 32.0, 1.0) var left_screen_margin: float = 14.0

var score: int = 0
var coins: int = 0
var time_left: float = 0.0
var started: bool = true
var finished: bool = false
var enemies: Array[Enemy] = []
var camera_progress_x: float = 0.0
var time_warning_played: bool = false
var death_animation_finished: bool = false
var audio: LevelAudio

@onready var hero: Player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	time_left = time_limit
	started = not start_locked
	_configure_level()
	if not started:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for node in find_children("*", "", true, false):
			node.process_mode = Node.PROCESS_MODE_PAUSABLE
		$PlayArea.process_mode = Node.PROCESS_MODE_ALWAYS
		$PlayArea.input_event.connect(_on_play_input_event)
		hero.set_physics_process(false)
	audio = AUDIO_SCENE.instantiate()
	add_child(audio)
	audio.jingle_finished.connect(_on_jingle_finished)
	hero.sound_requested.connect(_play_sound)
	hero.points_awarded.connect(_award_points)
	hero.death_finished.connect(_on_death_finished)
	for enemy in $Enemies.get_children():
		if enemy is Enemy:
			enemies.append(enemy)
			enemy.points_awarded.connect(_award_points)
			enemy.sound_requested.connect(_play_sound)
			enemy.set_physics_process(false)
	for coin in $Coins.get_children():
		coin.collected.connect(_collect_coin)
	$Finish/Goal.body_entered.connect(_finish)
	var manager = MysteryBlockManager.new()
	manager.name = "MysteryBlockManager"
	add_child(manager)
	manager.coin_collected.connect(_collect_coin)
	manager.sound_requested.connect(_play_sound)
	manager.setup($Terrain, hero)
	camera.limit_right = level_width
	_update_camera()
	_update_hud()
	if not started:
		hud.show_start_prompt()
		get_tree().paused = true

func _configure_level() -> void:
	pass

func start_game() -> void:
	if started:
		return
	started = true
	get_tree().paused = false
	hero.set_physics_process(true)
	hud.show_game_hud()

func _on_play_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		start_game()

func _unhandled_input(event: InputEvent) -> void:
	if finished:
		if event.is_action_pressed("ui_cancel") and not event.is_echo():
			get_viewport().set_input_as_handled()
			get_tree().paused = false
			get_tree().change_scene_to_file("res://cenas/main.tscn")
		elif event.is_action_pressed("ui_accept") and not next_level_path.is_empty() and not event.is_echo():
			get_viewport().set_input_as_handled()
			get_tree().change_scene_to_file(next_level_path)
		elif event.is_action_pressed("restart") and next_level_path.is_empty() and not event.is_echo():
			get_viewport().set_input_as_handled()
			_restart()
		return
	if event.is_action_pressed("restart") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_restart()

func _physics_process(delta: float) -> void:
	if not started or finished:
		return
	_update_camera()
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead and not enemy.is_physics_processing():
			if absf(enemy.position.x - hero.position.x) < activation_distance:
				enemy.set_physics_process(true)
	if not hero.is_dead:
		time_left = maxf(0, time_left - delta)
		if not time_warning_played and time_left > 0 and time_left <= 20.0:
			time_warning_played = true
			_play_sound(&"warning")
		if time_left <= 0:
			hud.show_timeout()
			hero.die()
		elif hero.position.y > fall_limit:
			hero.die()
	_update_hud()
	if score >= minimum_score and $Finish/Goal.overlaps_body(hero):
		_finish(hero)

func _update_camera() -> void:
	var half_width = get_viewport_rect().size.x / (2.0 * camera.zoom.x)
	var max_x = maxf(half_width, level_width - half_width)
	var target_x = clampf(hero.global_position.x + camera_lookahead, half_width, max_x)
	camera_progress_x = clampf(maxf(camera_progress_x, target_x), half_width, max_x)
	camera.global_position.x = camera_progress_x
	hero.minimum_x = camera_progress_x - half_width + left_screen_margin

func _collect_coin() -> void:
	_play_sound(&"coin")
	coins += 1
	score += 200
	_update_hud()

func _award_points(points: int, location: Vector2) -> void:
	score += points
	var label = POINTS_LABEL_SCENE.instantiate()
	label.text = str(points)
	label.position = $Effects.to_local(location) + Vector2(-20, -28)
	$Effects.add_child(label)
	_update_hud()

func _update_hud() -> void:
	hud.update_stats(score, coins, time_left, minimum_score)

func _restart() -> void:
	get_tree().reload_current_scene()

func _finish(body: Node2D) -> void:
	if body != hero or hero.is_dead or finished or time_left <= 0:
		return
	if score < minimum_score:
		hud.show_score_required(minimum_score - score)
		return
	finished = true
	score += ceili(time_left) * 10 + 1000
	hero.celebrate()
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.set_physics_process(false)
	_update_hud()
	hud.show_completion(score, not next_level_path.is_empty())
	audio.play(&"stage_clear" if not next_level_path.is_empty() else &"world_clear")

func _play_sound(sound: StringName) -> void:
	if hero.is_dead and sound != &"death":
		return
	if finished:
		return
	audio.play(&"game_over" if sound == &"death" and time_left <= 0 else sound)

func _on_death_finished() -> void:
	# Both the animation and its audio must finish before replacing the scene.
	death_animation_finished = true
	if not audio.is_jingle_playing():
		_restart()

func _on_jingle_finished() -> void:
	if death_animation_finished and hero.is_dead:
		_restart()
