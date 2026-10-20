class_name Koopa
extends Enemy

const KOOPA_SHELL_SHAPE = preload("res://resources/CollisionShapes/koopa_shell.tres")
const KOOPA_SHELL_POSITION = Vector2(0, 5)

@export var slide_speed: float = 200.0

var in_a_shell: bool = false

func _ready() -> void:
	_update_facing_direction()

func die() -> void:
	if in_a_shell or is_dead:
		return
	super.die()
	$CollisionShape2D.set_deferred("shape", KOOPA_SHELL_SHAPE)
	$CollisionShape2D.set_deferred("position", KOOPA_SHELL_POSITION)
	$Hitbox/CollisionShape2D.set_deferred("shape", KOOPA_SHELL_SHAPE)
	$Hitbox/CollisionShape2D.set_deferred("position", KOOPA_SHELL_POSITION)
	in_a_shell = true

func on_stomp(player_position: Vector2) -> void:
	var movement_direction = 1 if player_position.x <= global_position.x else -1
	horizontal_speed = -movement_direction * slide_speed
	avoid_ledges = false
	_update_facing_direction()

func stop_shell() -> void:
	horizontal_speed = 0
	velocity.x = 0

func is_moving_shell() -> bool:
	return in_a_shell and horizontal_speed != 0

func _on_direction_changed() -> void:
	_update_facing_direction()

func _update_facing_direction() -> void:
	animated_sprite_2d.flip_h = horizontal_speed > 0
