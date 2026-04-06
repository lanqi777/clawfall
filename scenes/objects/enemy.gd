extends Node2D

@onready var timer: Timer = $Timer

var grabbable_bullet = preload("res://scenes/objects/bullet_grabbable.tscn")
var danger_bullet = preload("res://scenes/objects/bullet_danger.tscn")

var player: Node2D

# 射击模式：0=瞄准, 1=扇形, 2=螺旋
@export var shoot_pattern: int = 0
var spiral_angle: float = 0.0
var pattern_timer: float = 0.0
var shoot_count: int = 0

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	if Global.game_state == Global.GameState.PLAYING:
		pattern_timer += delta

# 射击主循环
func _on_timer_timeout() -> void:
	if Global.game_state != Global.GameState.PLAYING:
		return

	shoot_count += 1

	# 根据波次动态选择射击模式
	var wave = Global.current_wave
	if wave >= 3 and pattern_timer > 8.0:
		shoot_pattern = randi() % min(1 + floor(wave / 2), 3)
		pattern_timer = 0.0

	# 波次越高射速越快
	var base_wait = max(timer.wait_time - (wave - 1) * 0.1, 0.5)
	timer.wait_time = base_wait

	# 波次高时增加危险弹幕概率
	var danger_chance = 0.5 + wave * 0.03
	danger_chance = min(danger_chance, 0.8)

	match shoot_pattern:
		0:
			_shoot_aimed(danger_chance)
		1:
			_shoot_spread(danger_chance)
		2:
			_shoot_spiral()

# ===== 模式1：瞄准玩家单发 =====
func _shoot_aimed(danger_chance: float) -> void:
	var is_danger = randf() > danger_chance
	var scene = danger_bullet if is_danger else grabbable_bullet
	var bullet = scene.instantiate()

	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position

	if player:
		var dir = (player.global_position - global_position).normalized()
		bullet.direction = dir
		bullet.rotation = dir.angle()

	# 波次速度加成
	bullet.speed *= (1.0 + (Global.current_wave - 1) * 0.06)

# ===== 模式2：扇形弹幕 =====
func _shoot_spread(danger_chance: float) -> void:
	var count = min(3 + floor(Global.current_wave / 3), 7)
	var base_angle = 0.0
	if player:
		base_angle = (player.global_position - global_position).angle()

	for i in range(count):
		var angle_offset = (float(i) - float(count - 1) / 2.0) * 0.3
		var is_danger = randf() > (danger_chance - 0.1)  # 扇形稍多一些危险弹幕
		var scene = danger_bullet if is_danger else grabbable_bullet
		var bullet = scene.instantiate()

		get_tree().current_scene.add_child(bullet)
		bullet.global_position = global_position

		var dir = Vector2.from_angle(base_angle + angle_offset)
		bullet.direction = dir
		bullet.rotation = dir.angle()
		bullet.speed *= (1.0 + (Global.current_wave - 1) * 0.04)

# ===== 模式3：螺旋弹幕 =====
func _shoot_spiral() -> void:
	var bullet = danger_bullet.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position

	spiral_angle += 0.7
	var dir = Vector2.from_angle(spiral_angle)
	bullet.direction = dir
	bullet.rotation = dir.angle()
