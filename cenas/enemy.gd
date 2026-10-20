class_name Enemy
extends CharacterBody2D

signal points_awarded(points: int, location: Vector2)

@export var horizontal_speed: float = 20.0
@export var gravity: float = 980.0
@export var avoid_ledges: bool = true
@export var ledge_check_offset: float = 6.0

var is_dead: bool = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ledge_ray: RayCast2D = $RayCast2D
@onready var hitbox: Area2D = $Hitbox

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if horizontal_speed != 0:
		ledge_ray.position.x = -signf(horizontal_speed) * ledge_check_offset
		ledge_ray.force_raycast_update()
		if is_on_wall() or (avoid_ledges and is_on_floor() and not ledge_ray.is_colliding()):
			horizontal_speed *= -1
			_on_direction_changed()
	velocity.x = -horizontal_speed
	if not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()
	if global_position.y > 400:
		queue_free()

func die() -> void:
	horizontal_speed = 0
	animated_sprite_2d.play("dead")

func disable_interactions() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	hitbox.set_deferred("collision_layer", 0)
	hitbox.set_deferred("collision_mask", 0)
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)

func die_from_hit() -> void:
	if is_dead:
		return
	disable_interactions()
	points_awarded.emit(100, global_position)
	rotation_degrees = 180
	var die_tween = create_tween()
	die_tween.tween_property(self, "position", position + Vector2(0, -25), 0.2)
	die_tween.tween_property(self, "position", position + Vector2(0, 500), 0.4)
	die_tween.tween_callback(queue_free)

func _on_hitbox_area_entered(area: Area2D) -> void:
	var other = area.get_parent()
	if other is Enemy and not other.is_dead and other.is_moving_shell():
		die_from_hit()

func is_moving_shell() -> bool:
	return false

func _on_direction_changed() -> void:
	pass
