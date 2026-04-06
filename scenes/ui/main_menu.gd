extends Control

@onready var btn_normal: Button = $VBoxContainer/BtnNormal
@onready var btn_gravity: Button = $VBoxContainer/BtnGravity
@onready var btn_acid_rain: Button = $VBoxContainer/BtnAcidRain
@onready var btn_lava: Button = $VBoxContainer/BtnLava
@onready var btn_settings: Button = $VBoxContainer/BtnSettings
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var high_score_labels: Dictionary = {
	Global.EnvType.NORMAL: $VBoxContainer/HSNormal,
	Global.EnvType.GRAVITY: $VBoxContainer/HSGraivty,
	Global.EnvType.ACID_RAIN: $VBoxContainer/HSAcidRain,
	Global.EnvType.LAVA: $VBoxContainer/HSLava,
}

func _ready() -> void:
	btn_normal.pressed.connect(_on_btn_normal_pressed)
	btn_gravity.pressed.connect(_on_btn_gravity_pressed)
	btn_acid_rain.pressed.connect(_on_btn_acid_rain_pressed)
	btn_lava.pressed.connect(_on_btn_lava_pressed)
	btn_settings.pressed.connect(_on_btn_settings_pressed)
	_refresh_high_scores()

func _refresh_high_scores() -> void:
	for env in high_score_labels:
		var label = high_score_labels[env]
		if label:
			var hs = Global.get_high_score(env)
			label.text = "最高分: %d" % hs

func _on_btn_normal_pressed() -> void:
	start_game(Global.EnvType.NORMAL)

func _on_btn_gravity_pressed() -> void:
	start_game(Global.EnvType.GRAVITY)

func _on_btn_acid_rain_pressed() -> void:
	start_game(Global.EnvType.ACID_RAIN)

func _on_btn_lava_pressed() -> void:
	start_game(Global.EnvType.LAVA)

func _on_btn_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/settings_screen.tscn")

func start_game(env: Global.EnvType) -> void:
	Global.selected_env = env
	Global.reset_game()
	Global.game_state = Global.GameState.PLAYING
	get_tree().change_scene_to_file("res://scenes/main.tscn")
