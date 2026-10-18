extends Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label_tween = create_tween()
	label_tween.tween_property(self, "position", Vector2(0, -10), 0.5).as_relative()
	label_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	label_tween.tween_callback(queue_free)
