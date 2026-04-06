extends Area2D

enum State { IDLE, EXTENDING, RETRACTING }
var current_state = State.IDLE

@export var base_speed: float = 600.0
@export var max_length: float = 500.0

var direction: Vector2 = Vector2.ZERO
var origin_pos: Vector2 = Vector2.ZERO
var current_speed: float = 600.0

# 抓到的物品列表
var grabbed_items: Array[Area2D] = []

# 信号：返回时携带物品
signal returned_to_player(items: Array[Area2D])
# 信号：碰到熔岩
signal hit_lava

# 重力异常相关
var is_drifting: bool = false
var drift_time: float = 0.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	match current_state:
		State.EXTENDING:
			# 重力异常环境：飞行方向产生正弦抖动
			if is_drifting:
				drift_time += delta
				direction.x += sin(drift_time * 5.0) * 0.2
				direction = direction.normalized()
				rotation = direction.angle()

			position += direction * current_speed * delta

			# 磁铁效果：吸引附近的可抓取物
			if Global.magnet_active:
				var grabbables = get_tree().get_nodes_in_group("grabbable")
				for g in grabbables:
					if is_instance_valid(g) and g not in grabbed_items:
						var dist = global_position.distance_to(g.global_position)
						if dist < Global.magnet_range and dist > 1:
							var pull_dir = (global_position - g.global_position).normalized()
							g.global_position += pull_dir * 200.0 * delta

			# 到达最大长度或飞出屏幕则收回
			if position.distance_to(origin_pos) >= max_length or not get_viewport_rect().has_point(global_position):
				start_retracting()

		State.RETRACTING:
			var back_dir = (origin_pos - position).normalized()
			position += back_dir * current_speed * delta

			# 所有抓到的物品跟随爪子
			for item in grabbed_items:
				if is_instance_valid(item):
					item.global_position = global_position

			# 回到原点则完成
			if position.distance_to(origin_pos) < current_speed * delta:
				position = origin_pos
				current_state = State.IDLE
				returned_to_player.emit(grabbed_items)
				grabbed_items.clear()
				current_speed = base_speed * Global.claw_speed_multiplier

# ===== 发射 =====
func shoot(target_dir: Vector2, start_pos: Vector2) -> void:
	if current_state != State.IDLE:
		return

	direction = target_dir.normalized()
	origin_pos = start_pos
	position = start_pos
	current_speed = base_speed * Global.claw_speed_multiplier
	current_state = State.EXTENDING
	rotation = direction.angle()

# ===== 碰撞检测 =====
func _on_area_entered(area: Area2D) -> void:
	# 碰到熔岩 → 受伤并强制收回
	if current_state == State.EXTENDING and area.is_in_group("lava"):
		print("【警告】爪子触碰熔岩，强制收回并受损！")
		hit_lava.emit()
		start_retracting()
		return

	# 抓取可抓取物
	if current_state == State.EXTENDING and area.is_in_group("grabbable"):
		var max_cap = Global.claw_max_capacity
		if grabbed_items.size() < max_cap:
			grabbed_items.append(area)
			# 叠加重量减速
			current_speed = max(current_speed - area.weight, 50.0)

			# 容量满了就收回；没满继续穿透
			if grabbed_items.size() >= max_cap:
				start_retracting()

func start_retracting() -> void:
	current_state = State.RETRACTING

# ===== 重力异常：启用方向漂移 =====
func enable_drift() -> void:
	is_drifting = true
