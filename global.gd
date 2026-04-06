extends Node

# ===== 环境枚举 =====
enum EnvType { NORMAL, GRAVITY, ACID_RAIN, LAVA }

# ===== 游戏状态 =====
enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

# ===== 能力类型 =====
enum PowerUpType { SPEED, SHIELD, DOUBLE_GRAB, MAGNET }

# 玩家选择的环境
var selected_env: EnvType = EnvType.NORMAL
var game_state: GameState = GameState.MENU

# ===== 分数与记录 =====
var score: int = 0
var high_scores: Dictionary = {
	EnvType.NORMAL: 0,
	EnvType.GRAVITY: 0,
	EnvType.ACID_RAIN: 0,
	EnvType.LAVA: 0
}

# ===== 连击系统 =====
var combo: int = 0
var combo_timer: float = 0.0
var max_combo: int = 0
var combo_time_window: float = 3.0  # 3秒内连续抓取算连击

# ===== 波次系统 =====
var current_wave: int = 1
var wave_timer: float = 0.0
var wave_interval: float = 20.0  # 每20秒进入下一波

# ===== 玩家属性（可被能力修改） =====
var player_speed_multiplier: float = 1.0
var claw_speed_multiplier: float = 1.0
var claw_max_capacity: int = 1
var shield_active: bool = false
var shield_hits: int = 0
var magnet_active: bool = false
var magnet_range: float = 80.0

# 能力持续时间计时器
var active_powerups: Dictionary = {}

# ===== 游戏统计 =====
var total_minerals_grabbed: int = 0
var total_danger_dodged: int = 0
var longest_claw_shot: float = 0.0

func _ready() -> void:
	load_high_scores()

func _process(delta: float) -> void:
	if game_state != GameState.PLAYING:
		return

	# 更新连击计时器
	if combo > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			if combo > max_combo:
				max_combo = combo
			combo = 0

	# 更新波次计时器
	wave_timer += delta
	if wave_timer >= wave_interval:
		wave_timer = 0.0
		current_wave += 1
		wave_interval = max(wave_interval - 1.0, 10.0)
		print("【系统】第 %d 波来袭！" % current_wave)
		# 通知生成器波次变化
		var spawner = get_tree().current_scene.get_node_or_null("Spawner")
		if spawner and spawner.has_method("on_wave_changed"):
			spawner.on_wave_changed()

	# 更新能力持续时间
	var expired: Array = []
	for powerup_type in active_powerups:
		active_powerups[powerup_type] -= delta
		if active_powerups[powerup_type] <= 0:
			expired.append(powerup_type)
	for pt in expired:
		deactivate_powerup(pt)

# ===== 连击 =====
func add_combo() -> void:
	combo += 1
	combo_timer = combo_time_window
	if combo > max_combo:
		max_combo = combo

func get_combo_multiplier() -> float:
	if combo >= 10: return 3.0
	if combo >= 7: return 2.5
	if combo >= 5: return 2.0
	if combo >= 3: return 1.5
	return 1.0

# ===== 能力系统 =====
func activate_powerup(type: PowerUpType, duration: float = 8.0) -> void:
	active_powerups[type] = duration
	match type:
		PowerUpType.SPEED:
			player_speed_multiplier = 1.5
			claw_speed_multiplier = 1.3
		PowerUpType.SHIELD:
			shield_active = true
			shield_hits = 2
		PowerUpType.DOUBLE_GRAB:
			claw_max_capacity = 2
		PowerUpType.MAGNET:
			magnet_active = true
	print("【能力激活】%s, 持续 %.1f 秒" % [PowerUpType.keys()[type], duration])

func deactivate_powerup(type: PowerUpType) -> void:
	active_powerups.erase(type)
	match type:
		PowerUpType.SPEED:
			player_speed_multiplier = 1.0
			claw_speed_multiplier = 1.0
		PowerUpType.SHIELD:
			shield_active = false
			shield_hits = 0
		PowerUpType.DOUBLE_GRAB:
			claw_max_capacity = 1
		PowerUpType.MAGNET:
			magnet_active = false
	print("【能力失效】%s" % PowerUpType.keys()[type])

func has_powerup(type: PowerUpType) -> bool:
	return type in active_powerups

func get_powerup_remaining(type: PowerUpType) -> float:
	return active_powerups.get(type, 0.0)

# ===== 高分 =====
func get_high_score(env: EnvType) -> int:
	return high_scores.get(env, 0)

func update_high_score(env: EnvType, new_score: int) -> bool:
	if new_score > high_scores.get(env, 0):
		high_scores[env] = new_score
		save_high_scores()
		return true
	return false

# ===== 重置 =====
func reset_game() -> void:
	score = 0
	combo = 0
	max_combo = 0
	combo_timer = 0.0
	current_wave = 1
	wave_timer = 0.0
	wave_interval = 20.0
	player_speed_multiplier = 1.0
	claw_speed_multiplier = 1.0
	claw_max_capacity = 1
	shield_active = false
	shield_hits = 0
	magnet_active = false
	active_powerups.clear()
	total_minerals_grabbed = 0
	total_danger_dodged = 0
	longest_claw_shot = 0.0

# ===== 持久化 =====
func save_high_scores() -> void:
	var save_data = {}
	for key in high_scores:
		save_data[str(key)] = high_scores[key]
	var file = FileAccess.open("user://high_scores.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_high_scores() -> void:
	if FileAccess.file_exists("user://high_scores.json"):
		var file = FileAccess.open("user://high_scores.json", FileAccess.READ)
		if file:
			var data = JSON.parse_string(file.get_as_text())
			if data is Dictionary:
				for key in data:
					var int_key = int(key)
					if int_key in high_scores:
						high_scores[int_key] = data[key]
			file.close()
