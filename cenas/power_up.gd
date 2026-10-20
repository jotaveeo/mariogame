class_name PowerUp
extends CharacterBody2D

const MUSHROOM_TEXTURE = preload("res://Assets Super Mario Bros/Sprites/MagicMushroom.png")
const FLOWER_TEXTURE = preload("res://Assets Super Mario Bros/Sprites/ShootingFlower.png")
const GRAVITY: float = 980.0
const MUSHROOM_SPEED: float = 60.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var body_collision_shape: CollisionShape2D = $CollisionShape2D
@onready var pickup_area: Area2D = $PickupArea

var item_type: StringName
var active: bool = false
var collected: bool = false
var direction: float = 1.0

func setup(reward: StringName) -> void:
	item_type = reward

func _ready() -> void:
	sprite.texture = MUSHROOM_TEXTURE if item_type == &"mushroom" else FLOWER_TEXTURE
	pickup_area.monitoring = false
	body_collision_shape.set_deferred("disabled", true)
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector2(0, -16), 0.3)
	tween.tween_callback(_activate)

func _physics_process(delta: float) -> void:
	if active and not collected:
		for body in pickup_area.get_overlapping_bodies():
			_on_pickup_area_body_entered(body)
	if collected or not active or item_type != &"mushroom":
		return
	if is_on_wall():
		direction *= -1.0
	velocity.x = direction * MUSHROOM_SPEED
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _activate() -> void:
	active = true
	body_collision_shape.set_deferred("disabled", false)
	pickup_area.set_deferred("monitoring", true)

func _on_pickup_area_body_entered(body: Node2D) -> void:
	if collected or not body is Player:
		return
	if not body.apply_powerup(item_type):
		return
	collected = true
	pickup_area.set_deferred("monitoring", false)
	queue_free()
