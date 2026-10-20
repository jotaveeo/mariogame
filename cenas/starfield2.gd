@tool
extends Node2D

@export var sky_size: Vector2i = Vector2i(3520, 240):
	set(value):
		sky_size = value
		queue_redraw()

@export var sky_color: Color = Color("05091a"):
	set(value):
		sky_color = value
		queue_redraw()

@export_range(0, 1500, 1) var star_count: int = 260:
	set(value):
		star_count = value
		queue_redraw()

@export var star_seed: int = 1947:
	set(value):
		star_seed = value
		queue_redraw()

func _draw() -> void:
	if sky_size.x <= 0 or sky_size.y <= 0:
		return
	draw_rect(Rect2(Vector2.ZERO, Vector2(sky_size)), sky_color)
	var random = RandomNumberGenerator.new()
	random.seed = star_seed
	for index in range(star_count):
		var point = Vector2(random.randi_range(3, maxi(3, sky_size.x - 4)), random.randi_range(8, maxi(8, sky_size.y - 36)))
		var size_roll = random.randf()
		var size = 1 if size_roll < 0.78 else (2 if size_roll < 0.96 else 3)
		var tint = Color("6cf532ff") if random.randf() < 0.7 else Color("fff0cc")
		tint.a = random.randf_range(0.25, 0.65) if size == 1 else random.randf_range(0.7, 1.0)
		draw_rect(Rect2(point, Vector2(size, size)), tint)
		if size == 3:
			var halo = Color(tint, 0.18)
			draw_rect(Rect2(point + Vector2(-1, 1), Vector2(5, 1)), halo)
			draw_rect(Rect2(point + Vector2(1, -1), Vector2(1, 5)), halo)
