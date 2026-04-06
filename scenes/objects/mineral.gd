extends Area2D

# 矿物稀有度
enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY }

@export var rarity: Rarity = Rarity.COMMON
@export var score_value: int = 50
@export var weight: float = 300.0

# 漂浮动画
var is_floating: bool = false
var start_y: float = 0.0
var float_speed: float = 2.0
var float_amplitude: float = 30.0
var time_passed: float = 0.0

# 视觉
var original_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	start_y = position.y
	time_passed = randf() * 10.0  # 错开每个矿物的漂浮频率
	original_scale = scale

	# 根据稀有度设置属性
	_apply_rarity()

func _apply_rarity() -> void:
	match rarity:
		Rarity.COMMON:
			score_value = 50
			weight = 300.0
		Rarity.UNCOMMON:
			score_value = 100
			weight = 250.0
			float_amplitude = 40.0
		Rarity.RARE:
			score_value = 200
			weight = 200.0
			float_amplitude = 50.0
		Rarity.LEGENDARY:
			score_value = 500
			weight = 150.0
			float_amplitude = 60.0

func _process(delta: float) -> void:
	if is_floating:
		time_passed += delta
		position.y = start_y + sin(time_passed * float_speed) * float_amplitude

	# 稀有矿物呼吸光效
	if rarity >= Rarity.RARE:
		var pulse = 1.0 + sin(time_passed * 3.0) * 0.1
		scale = original_scale * pulse

# ===== 环境管理器调用的接口 =====
func enable_floating() -> void:
	is_floating = true

func increase_value(amount: int) -> void:
	score_value += amount
	# 稀有度可能提升
	if score_value >= 400:
		rarity = Rarity.LEGENDARY
	elif score_value >= 200:
		rarity = Rarity.RARE
	elif score_value >= 100:
		rarity = Rarity.UNCOMMON
	_apply_rarity()
