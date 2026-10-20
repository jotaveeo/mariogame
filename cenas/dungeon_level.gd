extends Node2D

const POINTS_LABEL_SCENE = preload("res://cenas/points_label.tscn")

@export var fall_margin: float = 64.0
@export var camera_lookahead: float = 48.0
@export var left_recoil_margin: float = 14.0
@export_range(1.0, 3600.0, 1.0) var time_limit: float = 120.0

@onready var terrain: TileMapLayer = $Terrain
@onready var hero: Player = $Player
@onready var camera: Camera2D = $Camera2D

var fall_limit: float
var camera_progress_x: float
var camera_half_width: float
var camera_max_x: float
var score: int = 0
var coins: int = 0
var time_left: float = 0.0
var enemies: Array[Enemy] = []

@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	time_left = time_limit
	var used_rect = terrain.get_used_rect()
	var tile_size = terrain.tile_set.tile_size
	var last_tile = used_rect.end - Vector2i.ONE
	var map_end = terrain.to_global(terrain.map_to_local(last_tile)) + Vector2(tile_size) / 2.0
	var map_right = map_end.x
	fall_limit = map_end.y + fall_margin

	camera.limit_left = 0
	camera.limit_right = ceili(map_right)
	camera_half_width = get_viewport_rect().size.x / (2.0 * camera.zoom.x)
	camera_max_x = maxf(camera_half_width, map_right - camera_half_width)
	camera_progress_x = clampf(maxf(camera_half_width, hero.global_position.x + camera_lookahead), camera_half_width, camera_max_x)
	camera.global_position.x = camera_progress_x
	hero.minimum_x = camera_progress_x - camera_half_width + left_recoil_margin
	hero.points_awarded.connect(_award_points)
	hero.death_finished.connect(_restart)
	for enemy in $Enemies.get_children():
		if enemy is Enemy:
			enemies.append(enemy)
		enemy.points_awarded.connect(_award_points)
	for coin in $Coins.get_children():
		coin.collected.connect(_collect_coin)
	var mystery_block_manager = MysteryBlockManager.new()
	mystery_block_manager.name = "MysteryBlockManager"
	add_child(mystery_block_manager)
	mystery_block_manager.coin_collected.connect(_collect_coin)
	mystery_block_manager.setup(terrain, hero)
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and not event.is_echo():
		_restart()
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	camera_progress_x = minf(camera_max_x, maxf(camera_progress_x, hero.global_position.x + camera_lookahead))
	camera.global_position.x = camera_progress_x
	hero.minimum_x = camera_progress_x - camera_half_width + left_recoil_margin
	if not hero.is_dead:
		time_left = maxf(0.0, time_left - delta)
		if time_left <= 0.0:
			hud.show_timeout()
			hero.die()
		elif hero.global_position.y > fall_limit:
			hero.die()
	_update_hud()

func _collect_coin() -> void:
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
	hud.update_stats(score, coins, time_left, 0)

func _restart() -> void:
	get_tree().reload_current_scene()
