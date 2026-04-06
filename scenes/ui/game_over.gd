extends CanvasLayer

# ===== 游戏结束画面 =====
@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var score_label: Label = $Panel/VBox/ScoreLabel
@onready var combo_label: Label = $Panel/VBox/ComboLabel
@onready var mineral_label: Label = $Panel/VBox/MineralLabel
@onready var wave_label: Label = $Panel/VBox/WaveLabel
@onready var new_record_label: Label = $Panel/VBox/NewRecordLabel
@onready var btn_restart: Button = $Panel/VBox/BtnRestart
@onready var btn_menu: Button = $Panel/VBox/BtnMenu

func _ready() -> void:
	visible = false
	# 关键：让游戏结束画面在暂停状态下仍然可交互
	process_mode = Node.PROCESS_MODE_ALWAYS
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)

func show_game_over(score: int, max_combo: int, minerals: int, wave: int, is_new_record: bool) -> void:
	visible = true

	title_label.text = "⛏️ 游戏结束"
	score_label.text = "💰 最终得分: %d" % score
	combo_label.text = "🔥 最大连击: %d" % max_combo
	mineral_label.text = "💎 抓取矿物: %d 个" % minerals
	wave_label.text = "🌊 坚持到: 第 %d 波" % wave

	if is_new_record:
		new_record_label.text = "🏆 新纪录！"
		new_record_label.visible = true
	else:
		new_record_label.visible = false

func _on_restart_pressed() -> void:
	get_tree().paused = false
	Global.reset_game()
	Global.game_state = Global.GameState.PLAYING
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_menu_pressed() -> void:
	get_tree().paused = false
	Global.game_state = Global.GameState.MENU
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
