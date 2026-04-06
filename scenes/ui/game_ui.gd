extends CanvasLayer

# ===== UI 节点引用 =====
@onready var time_label: Label = $Control/MarginContainer/HBoxContainer/TimeLabel
@onready var hp_label: Label = $Control/MarginContainer/HBoxContainer/HPLabel
@onready var score_label: Label = $Control/MarginContainer/HBoxContainer/ScoreLabel
@onready var wave_label: Label = $Control/MarginContainer/HBoxContainer/WaveLabel
@onready var combo_label: Label = $Control/ComboLabel
@onready var powerup_label: Label = $Control/PowerUpLabel
@onready var game_timer: Timer = $GameTimer

# 游戏数据
var score: int = 0
var hp: int = 3

func _ready() -> void:
	game_timer.timeout.connect(_on_timer_timeout)
	update_ui()

func _process(_delta: float) -> void:
	# 实时更新倒计时
	time_label.text = "时间: %ds  |" % ceili(game_timer.time_left)

	# 实时更新波次
	if wave_label:
		wave_label.text = " 第%d波 |" % Global.current_wave

	# 实时更新连击
	if combo_label:
		if Global.combo >= 2:
			var mult = Global.get_combo_multiplier()
			combo_label.text = "🔥 %d连击 x%.1f" % [Global.combo, mult]
			combo_label.visible = true
			# 连击越高字越大
			var s = min(1.0 + Global.combo * 0.05, 1.5)
			combo_label.scale = Vector2(s, s)
		else:
			combo_label.visible = false

	# 实时更新能力状态
	if powerup_label:
		var texts: PackedStringArray = []
		if Global.has_powerup(Global.PowerUpType.SHIELD):
			texts.append("🛡️%.0fs" % Global.get_powerup_remaining(Global.PowerUpType.SHIELD))
		if Global.has_powerup(Global.PowerUpType.SPEED):
			texts.append("⚡%.0fs" % Global.get_powerup_remaining(Global.PowerUpType.SPEED))
		if Global.has_powerup(Global.PowerUpType.DOUBLE_GRAB):
			texts.append("✌️%.0fs" % Global.get_powerup_remaining(Global.PowerUpType.DOUBLE_GRAB))
		if Global.has_powerup(Global.PowerUpType.MAGNET):
			texts.append("🧲%.0fs" % Global.get_powerup_remaining(Global.PowerUpType.MAGNET))
		if texts.size() > 0:
			powerup_label.text = "  ".join(texts)
			powerup_label.visible = true
		else:
			powerup_label.visible = false

# 加分
func add_score(amount: int) -> void:
	Global.score += amount
	score = Global.score
	update_ui()

# 刷新UI
func update_ui() -> void:
	# 生命值用图标显示
	var hearts = ""
	for i in range(3):
		if i < hp:
			hearts += "❤️"
		else:
			hearts += "🖤"
	hp_label.text = " %s |" % hearts
	score_label.text = " 💰%d" % score

# 倒计时结束
func _on_timer_timeout() -> void:
	print("【系统日志】矿坑坍塌！游戏结束。")
	Global.game_state = Global.GameState.GAME_OVER
	if Global.combo > Global.max_combo:
		Global.max_combo = Global.combo
	var is_new_record = Global.update_high_score(Global.selected_env, Global.score)
	var game_over = get_node_or_null("/root/Main/GameOverScreen")
	if game_over:
		game_over.show_game_over(
			Global.score, Global.max_combo,
			Global.total_minerals_grabbed, Global.current_wave,
			is_new_record
		)
	# 延迟一帧暂停
	await get_tree().process_frame
	get_tree().paused = true
