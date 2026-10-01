extends AnimatedSprite2D

class_name PlayerAnimatedSprite

func trigger_animation(velocity: Vector2, direction: int, player_mode: player.PlayerMode):
	var animation_prefix = player.PlayerMode.keys()[player_mode].to_snake_case()

	# Se está morto, tocar animação de morte e não interferir
	if animation == "small_death":
		return

	if not get_parent().is_on_floor():
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
