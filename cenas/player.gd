class_name Player
extends CharacterBody2D

enum PlayerMode {
	SMALL,
	BIG,
	SHOOTING
}

signal points_awarded(points: int, location: Vector2)
signal death_finished

@export_group("Locomotion")
@export var run_speed_damping: float = 2.0
@export var speed: float = 200.0
@export var jump_velocity: float = -350.0

@export_group("")
@export_group("Stomping Enemies")
@export var min_stomp_degree: float = 35.0
@export var max_stomp_degree: float = 145.0
@export var stomp_y_velocity: float = -150.0
@export_group("")

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var player_mode: PlayerMode = PlayerMode.SMALL
var is_dead: bool = false

@onready var animated_sprite_2d: PlayerAnimatedSprite = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
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

	move_and_slide()

func _on_area_2d_area_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy is Enemy:
		handle_enemy_collision(enemy)

func handle_enemy_collision(enemy: Enemy) -> void:
	if not is_instance_valid(enemy) or is_dead or enemy.is_dead:
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
			die()
	elif is_stomping:
		enemy.die()
		on_enemy_stomped()
		points_awarded.emit(100, enemy.global_position)
	else:
		die()

func die() -> void:
	if is_dead:
		return
	if player_mode == PlayerMode.SMALL:
		is_dead = true
		animated_sprite_2d.play("small_death")
		set_physics_process(false)
		set_deferred("collision_layer", 0)
		$Area2D.set_deferred("monitoring", false)

		var death_tween = create_tween()
		death_tween.tween_property(self, "position", position + Vector2(0, -48), .5)
		death_tween.chain().tween_property(self, "position", position + Vector2(0, 256), 1.0)
		death_tween.tween_callback(death_finished.emit)

func on_enemy_stomped() -> void:
	velocity.y = stomp_y_velocity


func celebrate() -> void:
	velocity = Vector2.ZERO
	set_physics_process(false)
	animated_sprite_2d.play("small_idle")
