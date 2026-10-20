extends CharacterBody2D

const SPEED: float = 180.0
const GRAVITY: float = 500.0
const BOUNCE_SPEED: float = -160.0
const LIFETIME: float = 3.0

var direction: float = 1.0
var lifetime: float = 0.0

func setup(horizontal_direction: int, spawn_position: Vector2) -> void:
	direction = float(horizontal_direction)
	global_position = spawn_position

func _physics_process(delta: float) -> void:
	lifetime += delta
	if lifetime >= LIFETIME:
		queue_free()
		return
	velocity.x = direction * SPEED
	velocity.y += GRAVITY * delta
	var collision = move_and_collide(velocity * delta)
	if collision:
		if collision.get_normal().y < -0.7 and velocity.y > 0.0:
			velocity.y = BOUNCE_SPEED
		else:
			queue_free()

func _on_hitbox_area_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy is Enemy and not enemy.is_dead:
		enemy.die_from_hit()
		queue_free()
