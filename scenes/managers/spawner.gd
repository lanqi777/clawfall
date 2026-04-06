extends Node

# ===== 生成管理器 =====
# 负责随机生成敌人和矿物
const Mineral = preload("res://scenes/objects/mineral.gd")
# 预加载场景
var mineral_scene = preload("res://scenes/objects/mineral.tscn")
var enemy_scene = preload("res://scenes/objects/enemy.tscn")

# 生成配置
@export var min_minerals: int = 3
@export var max_minerals: int = 6
@export var min_enemies: int = 2
@export var max_enemies: int = 4

# 生成区域边界（相对于屏幕）
@export var spawn_margin: float = 80.0  # 边缘留白
@export var spawn_margin_top: float = 100.0  # 顶部留白（给UI）
@export var spawn_margin_bottom: float = 150.0  # 底部留白

# 矿物稀有度权重（COMMON权重最高）
var rarity_weights: Dictionary = {
	Mineral.Rarity.COMMON: 60,
	Mineral.Rarity.UNCOMMON: 25,
	Mineral.Rarity.RARE: 12,
	Mineral.Rarity.LEGENDARY: 3
}

# 最小间距（防止物体重叠）
var min_distance: float = 120.0

# 存储已生成的对象
var spawned_minerals: Array[Node] = []
var spawned_enemies: Array[Node] = []

# 屏幕尺寸
var screen_size: Vector2

# 生成计时器
var spawn_check_timer: float = 0.0
var spawn_check_interval: float = 5.0  # 每5秒检查一次是否需要补充

func _ready() -> void:
	await get_tree().process_frame
	screen_size = get_viewport().get_visible_rect().size
	
	# 监听游戏状态变化
	Global.reset_game()
	
	# 初始生成
	initial_spawn()

func _process(delta: float) -> void:
	if Global.game_state != Global.GameState.PLAYING:
		return
	
	spawn_check_timer += delta
	if spawn_check_timer >= spawn_check_interval:
		spawn_check_timer = 0.0
		check_and_spawn()

# ===== 初始生成 =====
func initial_spawn() -> void:
	# 清理旧对象
	clear_all()
	
	# 根据波次调整生成数量
	var wave = Global.current_wave
	var mineral_count = randi_range(min_minerals, min(max_minerals, min_minerals + wave / 2))
	var enemy_count = randi_range(min_enemies, min(max_enemies, min_enemies + wave / 3))
	
	# 生成矿物
	for i in range(mineral_count):
		spawn_mineral()
	
	# 生成敌人
	for i in range(enemy_count):
		spawn_enemy()
	
	print("【生成器】初始生成完成：矿物 %d, 敌人 %d" % [mineral_count, enemy_count])

# ===== 检查并补充生成 =====
func check_and_spawn() -> void:
	# 清理已失效的引用
	spawned_minerals = spawned_minerals.filter(func(m): return is_instance_valid(m) and m.is_inside_tree())
	spawned_enemies = spawned_enemies.filter(func(e): return is_instance_valid(e) and e.is_inside_tree())
	
	var wave = Global.current_wave
	
	# 补充矿物
	var target_minerals = randi_range(min_minerals, min(max_minerals, min_minerals + wave / 2))
	while spawned_minerals.size() < target_minerals:
		spawn_mineral()
	
	# 补充敌人
	var target_enemies = randi_range(min_enemies, min(max_enemies, min_enemies + wave / 3))
	while spawned_enemies.size() < target_enemies:
		spawn_enemy()
	
	print("【生成器】补充检查：矿物 %d/%d, 敌人 %d/%d" % [
		spawned_minerals.size(), target_minerals,
		spawned_enemies.size(), target_enemies
	])

# ===== 生成单个矿物 =====
func spawn_mineral() -> Node:
	var mineral = mineral_scene.instantiate()
	
	# 随机位置
	var pos = get_random_position()
	
	# 检查是否与其他矿物重叠
	var attempts = 0
	while is_position_occupied(pos, spawned_minerals) and attempts < 20:
		pos = get_random_position()
		attempts += 1
	
	mineral.global_position = pos
	
	# 随机稀有度
	mineral.rarity = get_random_rarity()
	mineral._apply_rarity()
	
	# 随机初始浮动偏移
	mineral.time_passed = randf() * 10.0
	
	# 添加到场景
	get_tree().current_scene.get_node("Node2D").add_child(mineral)
	spawned_minerals.append(mineral)
	
	# 环境特殊处理
	if Global.selected_env == Global.EnvType.GRAVITY:
		mineral.enable_floating()
	
	return mineral

# ===== 生成单个敌人 =====
func spawn_enemy() -> Node:
	var enemy = enemy_scene.instantiate()
	
	# 随机位置
	var pos = get_random_position()
	
	# 检查是否与其他敌人重叠
	var attempts = 0
	while is_position_occupied(pos, spawned_enemies) and attempts < 20:
		pos = get_random_position()
		attempts += 1
	
	enemy.global_position = pos
	
	# 随机射击模式
	enemy.shoot_pattern = randi() % 3
	
	# 添加到场景
	get_tree().current_scene.get_node("Node2D").add_child(enemy)
	spawned_enemies.append(enemy)
	
	# 随机初始射击间隔（需要在添加到场景后设置，因为 @onready 还没生效）
	await get_tree().process_frame
	if is_instance_valid(enemy) and enemy.timer:
		enemy.timer.wait_time = randf_range(1.5, 3.0)
	
	return enemy

# ===== 获取随机位置 =====
func get_random_position() -> Vector2:
	var x = randf_range(spawn_margin, screen_size.x - spawn_margin)
	var y = randf_range(spawn_margin_top, screen_size.y - spawn_margin_bottom)
	return Vector2(x, y)

# ===== 检查位置是否被占用 =====
func is_position_occupied(pos: Vector2, objects: Array) -> bool:
	for obj in objects:
		if is_instance_valid(obj) and obj.global_position.distance_to(pos) < min_distance:
			return true
	return false

# ===== 根据权重获取随机稀有度 =====
func get_random_rarity():
	var total_weight = 0
	for weight in rarity_weights.values():
		total_weight += weight
	
	var roll = randi() % total_weight
	var cumulative = 0
	
	for rarity in [Mineral.Rarity.COMMON, Mineral.Rarity.UNCOMMON, Mineral.Rarity.RARE, Mineral.Rarity.LEGENDARY]:
		cumulative += rarity_weights[rarity]
		if roll < cumulative:
			return rarity
	
	return Mineral.Rarity.COMMON

# ===== 清理所有生成的对象 =====
func clear_all() -> void:
	for mineral in spawned_minerals:
		if is_instance_valid(mineral):
			mineral.queue_free()
	for enemy in spawned_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	spawned_minerals.clear()
	spawned_enemies.clear()

# ===== 波次更新时重新生成 =====
func on_wave_changed() -> void:
	# 波次增加时，可能增加更多敌人和矿物
	# 同时调整稀有度权重（后期稀有矿物概率略微提升）
	if Global.current_wave >= 3:
		rarity_weights[Mineral.Rarity.COMMON] = max(40, rarity_weights[Mineral.Rarity.COMMON] - 5)
		rarity_weights[Mineral.Rarity.UNCOMMON] = min(35, rarity_weights[Mineral.Rarity.UNCOMMON] + 3)
		rarity_weights[Mineral.Rarity.RARE] = min(20, rarity_weights[Mineral.Rarity.RARE] + 2)
		rarity_weights[Mineral.Rarity.LEGENDARY] = min(8, rarity_weights[Mineral.Rarity.LEGENDARY] + 1)
	
	print("【生成器】波次 %d，稀有度权重已调整" % Global.current_wave)
