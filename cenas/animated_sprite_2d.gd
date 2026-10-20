class_name PlayerAnimatedSprite
extends AnimatedSprite2D

# Keep the feet at the same height for both 16px and 32px sprites,
# including the old/new frames shown during a transformation.
func _ready() -> void:
	animation_changed.connect(_align_feet)
	frame_changed.connect(_align_feet)
	_align_feet()

func _align_feet() -> void:
	if sprite_frames == null or not sprite_frames.has_animation(animation):
		return
	var texture = sprite_frames.get_frame_texture(animation, frame)
	if texture != null:
		position.y = 8.0 - texture.get_height() / 2.0

func trigger_animation(velocity: Vector2, direction: int, player_mode: Player.PlayerMode, on_floor: bool) -> void:
	var animation_prefix = Player.PlayerMode.keys()[player_mode].to_snake_case()

	if not on_floor:
		play("%s_jump" % animation_prefix)

	elif sign(velocity.x) != sign(direction) && velocity.x != 0 && direction != 0:
		play("%s_slide" % animation_prefix)
		scale.x = direction

	else:
		if scale.x == 1 && sign(velocity.x) == -1:
			scale.x = -1
		elif scale.x == -1 && sign(velocity.x) == 1:
			scale.x = 1

		if velocity.x != 0:
			play("%s_run" % animation_prefix)
		else:
			play("%s_idle" % animation_prefix)
