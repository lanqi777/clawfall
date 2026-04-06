extends Node2D

@onready var claw: Area2D = $Claw
@onready var rope: Line2D = $Rope
@onready var hurtbox: Area2D = $Hurtbox
@onready var game_ui = get_node("/root/Main/GameUI")
@onready var hit_flash: AnimationPlayer = $HitFlash

# 移动参数
@export var move_speed: float = 200.0
var velocity: Vector2 = Vector2.ZERO

# 屏幕边界
var screen_bounds: Rect2

func _ready() -> void:
	rope.add_point(Vector2.ZERO)
	rope.add_point(Vector2.ZERO)
	rope.visible = false
	claw.returned_to_player.connect(_on_claw_returned)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	claw.hit_lava.connect(_on_claw_hit_lava)

	# 初始化屏幕边界
	await get_tree().process_frame  # 等一帧确保视口尺寸就绪
	screen_bounds = get_viewport_rect()
	screen_bounds.position.x += 40	
	screen_bounds.end.x -= 40
	screen_bounds.position.y += 20
	screen_bounds.end.y = screen_bounds.position.y + 80

	# 限制初始位置
	position.x = clampf(position.x, screen_bounds.position.x, screen_bounds.end.x)
	position.y = clampf(position.y, screen_bounds.position.y, screen_bounds.end.y)

# ===== 受伤处理 =====
func take_damage(source: String = "") -> void:
	if Global.shield_active:
		Global.shield_hits -= 1
		if Global.shield_hits <= 0:
			Global.deactivate_powerup(Global.PowerUpType.SHIELD)
		print("【护盾】抵挡了伤害！剩余 %d 次" % Global.shield_hits)
		_do_screen_shake(0.1, 3.0)  # 轻微震动
		return

	game_ui.hp -= 1
	game_ui.update_ui()
	_do_screen_shake(0.3, 8.0)
	_do_hit_flash()

	if game_ui.hp <= 0:
		print("【系统日志】%s, 游戏失败！" % source)
		_end_game()

func _do_screen_shake(duration: float, strength: float) -> void:
	var camera = get_node_or_null("/root/Main/MainCamera")
	if camera and camera.has_method("start_shake"):
		camera.start_shake(duration, strength)

func _do_hit_flash() -> void:
	if hit_flash and hit_flash.has_animation("flash"):
		hit_flash.play("flash")

# ===== 爪子返回结算 =====
func _on_claw_hit_lava() -> void:
	take_damage("玩家被岩浆烧毁")

func _on_claw_returned(items: Array[Area2D]) -> void:
	for item in items:
		if is_instance_valid(item):
			Global.add_combo()
			var multiplier = Global.get_combo_multiplier()
			var points = int(item.score_value * multiplier)
			game_ui.add_score(points)
			Global.total_minerals_grabbed += 1
			if item.is_in_group("mineral"):
				item.queue_free()

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("danger"):
		take_damage("玩家血量归零")
		area.queue_free()

# ===== 游戏结束 =====
func _end_game() -> void:
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
	# 延迟一帧暂停，确保结束画面能先渲染出来
	await get_tree().process_frame
	get_tree().paused = true

# ===== 输入处理 =====
func _input(event: InputEvent) -> void:
	if Global.game_state != Global.GameState.PLAYING:
		return

	# 鼠标左键发射爪子
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if claw.current_state == claw.State.IDLE:
			var target_dir = get_global_mouse_position() - global_position
			if target_dir.length() > 1:
				claw.shoot(target_dir, Vector2.ZERO)

	# 空格键也可以发射
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed:
		if claw.current_state == claw.State.IDLE:
			var target_dir = get_global_mouse_position() - global_position
			if target_dir.length() < 1:
				target_dir = Vector2.DOWN
			claw.shoot(target_dir, Vector2.ZERO)

# ===== 帧更新 =====
func _process(delta: float) -> void:
	if Global.game_state != Global.GameState.PLAYING:
		return

	# 玩家移动：A/D 或 左/右方向键，W/S 或 上/下方向键
	velocity = Vector2.ZERO
	var speed = move_speed * Global.player_speed_multiplier

	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		velocity.x = -speed
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		velocity.x = speed
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		velocity.y = -speed
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		velocity.y = speed

	# 对角线归一化
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed

	position += velocity * delta

	# 限制在屏幕边界内
	position.x = clampf(position.x, screen_bounds.position.x, screen_bounds.end.x)
	position.y = clampf(position.y, screen_bounds.position.y, screen_bounds.end.y)

	# 绳索更新
	if claw.current_state != claw.State.IDLE:
		rope.visible = true
		rope.set_point_position(0, Vector2.ZERO)
		rope.set_point_position(1, claw.position)
	else:
		rope.visible = false
