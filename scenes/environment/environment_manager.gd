extends Node

# ===== 环境管理器（增强版） =====
@onready var acid_rain_particles: GPUParticles2D = $AcidRainParticles
@onready var acid_rain_timer: Timer = $AcidRainTimer
@onready var mineral_value_timer: Timer = $MineralValueTimer

var lava_scene = preload("res://scenes/environment/lava_zone.tscn")
var ui_node: CanvasLayer

func _ready() -> void:
	ui_node = get_node("/root/Main/GameUI")

	acid_rain_timer.timeout.connect(_on_acid_rain_damage)
	mineral_value_timer.timeout.connect(_on_mineral_value_up)

	# 读取全局保存的环境类型并应用
	apply_environment(Global.selected_env)

func apply_environment(env_type: Global.EnvType) -> void:
	match env_type:
		Global.EnvType.GRAVITY:
			print("【环境】重力异常矿坑：物体开始漂浮！")
			get_tree().call_group("mineral", "enable_floating")
			get_tree().call_group("claw", "enable_drift")

		Global.EnvType.ACID_RAIN:
			print("【环境】酸雨矿坑：持续腐蚀，但矿石正在变质升值！")
			if acid_rain_particles:
				acid_rain_particles.emitting = true
			if acid_rain_timer:
				acid_rain_timer.start()
			if mineral_value_timer:
				mineral_value_timer.start()

		Global.EnvType.LAVA:
			print("【环境】熔岩矿洞：底部极其危险！")
			var lava = lava_scene.instantiate()
			add_child.call_deferred(lava)
			await get_tree().process_frame
			lava.global_position = Vector2(get_viewport().size.x / 2.0, get_viewport().size.y - 50)

		Global.EnvType.NORMAL:
			print("【环境】普通矿坑。")

# 酸雨扣血
func _on_acid_rain_damage() -> void:
	if ui_node and Global.game_state == Global.GameState.PLAYING:
		ui_node.hp -= 1
		ui_node.update_ui()
		print("【酸雨】腐蚀中！扣除 1 点生命")

		if ui_node.hp <= 0:
			print("【系统日志】酸雨腐蚀致死！")
			Global.game_state = Global.GameState.GAME_OVER
			if Global.combo > Global.max_combo:
				Global.max_combo = Global.combo
			var is_new = Global.update_high_score(Global.selected_env, Global.score)
			var game_over = get_node_or_null("/root/Main/GameOverScreen")
			if game_over:
				game_over.show_game_over(Global.score, Global.max_combo, Global.total_minerals_grabbed, Global.current_wave, is_new)
			await get_tree().process_frame
			get_tree().paused = true

# 矿物升值（酸雨环境特有）
func _on_mineral_value_up() -> void:
	get_tree().call_group("mineral", "increase_value", 10)
