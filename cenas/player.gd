class_name Player
extends CharacterBody2D

enum PlayerMode {
	SMALL,
	BIG,
	SHOOTING
}

signal points_awarded(points: int, location: Vector2)
signal death_finished
signal mystery_block_hit(terrain: TileMapLayer, cell: Vector2i)

const TRANSFORMATION_DURATION: float = 1.0
const TRANSFORMATION_FLASH_INTERVAL: float = 0.1

@export_group("Locomotion")
@export var run_speed_damping: float = 2.0
@export var speed: float = 200.0
@export var jump_velocity: float = -350.0
var minimum_x: float = -INF

@export_group("")
@export_group("Stomping Enemies")
@export var min_stomp_degree: float = 35.0
@export var max_stomp_degree: float = 145.0
@export var stomp_y_velocity: float = -150.0
@export_group("")

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var player_mode: PlayerMode = PlayerMode.SMALL
var is_dead: bool = false
var damage_invulnerability: float = 0.0
var shoot_cooldown: float = 0.0
var transformation_time_left: float = 0.0
var transformation_flash_time_left: float = 0.0
var transformation_from_mode: PlayerMode
var transformation_show_new_mode: bool = false

@onready var animated_sprite_2d: PlayerAnimatedSprite = $AnimatedSprite2D
@onready var body_collision_shape: CollisionShape2D = $BodyCollisionShape2D
@onready var area_collision_shape: CollisionShape2D = $Area2D/AreaCollisionShape2D

func _physics_process(delta: float) -> void:
	damage_invulnerability = maxf(0.0, damage_invulnerability - delta)
	shoot_cooldown = maxf(0.0, shoot_cooldown - delta)
	if transformation_time_left > 0.0:
		transformation_time_left = maxf(0.0, transformation_time_left - delta)
		transformation_flash_time_left -= delta
		if transformation_flash_time_left <= 0.0:
			transformation_flash_time_left += TRANSFORMATION_FLASH_INTERVAL
			transformation_show_new_mode = not transformation_show_new_mode
			_play_mode_idle(player_mode if transformation_show_new_mode else transformation_from_mode)
		if transformation_time_left == 0.0:
			_play_mode_idle(player_mode)
		return
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5
		
	var direction = Input.get_axis("left", "right")

	if direction:
		velocity.x = lerpf(velocity.x, speed * direction, 1.0 - exp(-run_speed_damping * delta))
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta)

	animated_sprite_2d.trigger_animation(velocity, direction, player_mode, is_on_floor())

	var was_rising = velocity.y < 0.0
	move_and_slide()
	if was_rising:
		for index in range(get_slide_collision_count()):
			var collision = get_slide_collision(index)
			if collision.get_normal().y < 0.7:
				continue
			var collided_terrain = collision.get_collider() as TileMapLayer
			if collided_terrain == null:
				continue
			var contact = collision.get_position() - collision.get_normal()
			var cell = collided_terrain.local_to_map(collided_terrain.to_local(contact))
			mystery_block_hit.emit(collided_terrain, cell)
	if global_position.x < minimum_x:
		global_position.x = minimum_x
		velocity.x = maxf(velocity.x, 0.0)
	if player_mode == PlayerMode.SHOOTING and Input.is_action_just_pressed("shoot"):
		_shoot_fireball()

func _on_area_2d_area_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy is Enemy:
		handle_enemy_collision(enemy)

func handle_enemy_collision(enemy: Enemy) -> void:
	if not is_instance_valid(enemy) or is_dead or damage_invulnerability > 0.0 or enemy.is_dead:
		return

	var angle_of_collision = rad_to_deg(global_position.angle_to_point(enemy.global_position))
	var is_stomping = velocity.y > 0 and angle_of_collision > min_stomp_degree and angle_of_collision < max_stomp_degree

	if enemy is Koopa and enemy.in_a_shell:
		if is_stomping:
			if enemy.horizontal_speed != 0:
				enemy.stop_shell()
			else:
				enemy.on_stomp(global_position)
			on_enemy_stomped()
		elif enemy.horizontal_speed == 0:
			enemy.on_stomp(global_position)
		else:
			take_damage()
	elif is_stomping:
		enemy.die()
		on_enemy_stomped()
		points_awarded.emit(100, enemy.global_position)
	else:
		take_damage()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	animated_sprite_2d.play("small_death")
	set_physics_process(false)
	set_deferred("collision_layer", 0)
	$Area2D.set_deferred("monitoring", false)

	var death_tween = create_tween()
	death_tween.tween_property(self, "position", position + Vector2(0, -48), .5)
	death_tween.chain().tween_property(self, "position", position + Vector2(0, 256), 1.0)
	death_tween.tween_callback(death_finished.emit)

func apply_powerup(item_type: StringName) -> bool:
	if is_dead or transformation_time_left > 0.0:
		return false
	if item_type == &"mushroom":
		if player_mode == PlayerMode.SMALL:
			_set_player_mode(PlayerMode.BIG)
	elif item_type == &"flower":
		_set_player_mode(PlayerMode.SHOOTING)
	else:
		return false
	return true

func take_damage() -> void:
	if is_dead or damage_invulnerability > 0.0 or transformation_time_left > 0.0:
		return
	if player_mode == PlayerMode.SHOOTING:
		_set_player_mode(PlayerMode.BIG)
	elif player_mode == PlayerMode.BIG:
		_set_player_mode(PlayerMode.SMALL)
	else:
		die()
	damage_invulnerability = 1.0

func _set_player_mode(new_mode: PlayerMode) -> void:
	if player_mode == new_mode:
		return
	transformation_from_mode = player_mode
	player_mode = new_mode
	transformation_time_left = TRANSFORMATION_DURATION
	transformation_flash_time_left = 0.0
	transformation_show_new_mode = false
	var is_small = new_mode == PlayerMode.SMALL
	var shape_size = Vector2(12.0, 16.0) if is_small else Vector2(12.0, 32.0)
	var shape_offset = (16.0 - shape_size.y) / 2.0
	var body_shape = RectangleShape2D.new()
	body_shape.size = shape_size
	var area_shape = RectangleShape2D.new()
	area_shape.size = shape_size
	body_collision_shape.set_deferred("shape", body_shape)
	area_collision_shape.set_deferred("shape", area_shape)
	body_collision_shape.set_deferred("position", Vector2(body_collision_shape.position.x, shape_offset))
	area_collision_shape.set_deferred("position", Vector2(area_collision_shape.position.x, shape_offset))
	velocity = Vector2.ZERO
	_play_mode_idle(transformation_from_mode)

func _play_mode_idle(mode: PlayerMode) -> void:
	animated_sprite_2d.play(PlayerMode.keys()[mode].to_snake_case() + "_idle")

func _shoot_fireball() -> void:
	if shoot_cooldown > 0.0:
		return
	var fireball_scene = preload("res://cenas/fireball.tscn")
	var fireball = fireball_scene.instantiate()
	var direction = -1 if animated_sprite_2d.scale.x < 0.0 else 1
	get_parent().add_child(fireball)
	fireball.setup(direction, global_position + Vector2(12.0 * direction, -2.0))
	shoot_cooldown = 0.35
	animated_sprite_2d.play("shooting")

func on_enemy_stomped() -> void:
	velocity.y = stomp_y_velocity


func celebrate() -> void:
	velocity = Vector2.ZERO
	set_physics_process(false)
	animated_sprite_2d.play(PlayerMode.keys()[player_mode].to_snake_case() + "_idle")
