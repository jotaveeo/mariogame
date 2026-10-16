extends Enemy

func die() -> void:
	if is_dead:
		return
	super.die()
	disable_interactions()
	get_tree().create_timer(0.5).timeout.connect(queue_free)
