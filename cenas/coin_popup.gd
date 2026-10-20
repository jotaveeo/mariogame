extends Node2D

func _ready() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector2(0, -24), 0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
