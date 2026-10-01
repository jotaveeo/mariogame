extends Area2D

class_name Enemy

const POINTS_LABEL_SCENE = preload("res://cenas/points_label.tscn")

@export var horizontal_speed = 20
@export var vertical_speed = 100

@onready var ray_cast_2d = $RayCast2D as RayCast2D
@onready var animated_sprite_2d = $AnimatedSprite2D as AnimatedSprite2D

func _process(delta):
	var hs = horizontal_speed if horizontal_speed != null else 20.0
	var vs = vertical_speed if vertical_speed != null else 100.0
	position.x -= hs * delta

	if !ray_cast_2d.is_colliding():
		position.y += vs * delta

func die():
	horizontal_speed = 0
	vertical_speed = 0
	animated_sprite_2d.play("dead")
	# Goomba: achatar e sumir depois
	if "Goomba" in get_class():
		animated_sprite_2d.scale.y = 0.3
		get_tree().create_timer(0.5).timeout.connect(queue_free)

func die_from_hit():
	set_collision_layer_value(3, false)
	set_collision_mask_value(3, false)

	rotation_degrees = 180

	horizontal_speed = 0
	vertical_speed = 0

	var die_tween = get_tree().create_tween()
	die_tween.tween_property(self, "position", position + Vector2(0, -25), .2)
	die_tween.chain().tween_property(self, "position", position + Vector2(0, 500), .4)
	
	var points_label = POINTS_LABEL_SCENE.instantiate()
	points_label.position = self.position + Vector2(-20, -20)
	get_tree().root.add_child(points_label)
	
	die_tween.finished.connect(queue_free)
	
func _on_area_entered(area):
	if area.get("in_a_shell") == true and area.get("horizontal_speed") != 0:
		die_from_hit()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
