extends Node2D

const POINTS_LABEL_SCENE = preload("res://cenas/points_label.tscn")

@export var level_width: int = 3520
@export_range(1.0, 3600.0, 1.0) var time_limit: float = 60.0
@export_range(0, 100000, 100) var minimum_score: int = 2000
@export var fall_limit: float = 300.0
@export var activation_distance: float = 220.0

var score: int = 0
var coins: int = 0
var time_left: float = 0.0
var finished: bool = false
var enemies: Array[Enemy] = []

@onready var hero: Player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	time_left = time_limit
	hero.points_awarded.connect(_award_points)
	hero.death_finished.connect(_restart)
	for enemy in $Enemies.get_children():
		if enemy is Enemy:
			enemies.append(enemy)
			enemy.points_awarded.connect(_award_points)
			enemy.set_physics_process(false)
	for coin in $Coins.get_children():
		coin.collected.connect(_collect_coin)
	$Finish/Goal.body_entered.connect(_finish)
	camera.limit_right = level_width
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and not event.is_echo():
		_restart()
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if finished:
		return
	var half_width = get_viewport_rect().size.x / (2.0 * camera.zoom.x)
	camera.position.x = clampf(hero.position.x + 48, half_width, level_width - half_width)
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead and not enemy.is_physics_processing():
			if absf(enemy.position.x - hero.position.x) < activation_distance:
				enemy.set_physics_process(true)
	if not hero.is_dead:
		time_left = maxf(0, time_left - delta)
		if time_left <= 0:
			hud.show_timeout()
			hero.die()
		elif hero.position.y > fall_limit:
			hero.die()
	_update_hud()
	if score >= minimum_score and $Finish/Goal.overlaps_body(hero):
		_finish(hero)

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
	hud.show_completion(score)
