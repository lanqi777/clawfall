extends Area2D

@export var speed: float = 150.0
@export var weight: float = 100.0
@export var score_value: int = 20

# 飞行方向，默认向下
var direction: Vector2 = Vector2.DOWN

func _process(delta: float) -> void:
	position += direction * speed * delta

	# 飞出屏幕则销毁
	var screen_rect = get_viewport_rect().grow(100)
	if not screen_rect.has_point(global_position):
		queue_free()
