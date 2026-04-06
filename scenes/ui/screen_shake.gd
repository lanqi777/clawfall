extends Camera2D

# ===== 屏幕震动组件 =====
@export var decay_speed: float = 5.0

var shake_strength: float = 0.0
var shake_duration: float = 0.0
var is_shaking: bool = false

var _random: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_random.randomize()
	enabled = true

func _process(delta: float) -> void:
	if is_shaking:
		shake_duration -= delta
		if shake_duration <= 0:
			is_shaking = false
			shake_strength = 0.0
			offset = Vector2.ZERO
			return

		# 衰减震动强度
		var current_strength = shake_strength * (shake_duration / 0.3)  # 0.3秒为参考时间
		current_strength = maxf(current_strength, 0.0)

		# 随机偏移
		offset.x = _random.randf_range(-current_strength, current_strength)
		offset.y = _random.randf_range(-current_strength, current_strength)

# 开始震动
func start_shake(duration: float, strength: float) -> void:
	shake_duration = duration
	shake_strength = strength
	is_shaking = true

# 停止震动
func stop_shake() -> void:
	is_shaking = false
	shake_strength = 0.0
	offset = Vector2.ZERO
