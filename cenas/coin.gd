extends Area2D

signal collected
var taken: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if taken or not body is Player or body.is_dead:
		return
	taken = true
	collected.emit()
	queue_free()
