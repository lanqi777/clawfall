extends Node

# ===== 设置管理器 =====
# 单例，负责保存/加载所有游戏设置

# ===== 画面设置 =====
var resolution: Vector2i = Vector2i(1920, 1080)
var window_mode: int = 0  # 0=窗口, 1=全屏, 2=无边框
var brightness: float = 1.0  # 0.5 - 1.5
var contrast: float = 1.0    # 0.5 - 1.5
var gamma: float = 1.0       # 0.5 - 1.5
var saturation: float = 1.0  # 0.0 - 2.0
var vsync_mode: int = 1      # 0=禁用, 1=启用, 2=自适应
var show_fps: bool = false
var show_perf_monitor: bool = false

# ===== 声音设置 =====
var master_volume: float = 1.0   # 0.0 - 1.0
var bgm_volume: float = 0.8      # 0.0 - 1.0
var sfx_volume: float = 1.0      # 0.0 - 1.0

# ===== 操作设置 =====
# 默认键位
var key_bindings: Dictionary = {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"grab": [KEY_SPACE, KEY_ENTER],
	"pause": [KEY_ESCAPE, KEY_P]
}

# ===== 辅助与无障碍 =====
var colorblind_mode: int = 0  # 0=无, 1=红绿, 2=蓝黄, 3=全色盲
var text_size: int = 1        # 0=小, 1=中, 2=大
var ui_scale: float = 1.0     # 0.75 - 1.5

# ===== 其他设置 =====
var language: int = 0  # 0=中文, 1=English

# ===== 内部 =====
var settings_path: String = "user://settings.json"
var _window: Window

signal settings_changed(setting_name: String, value)

func _ready() -> void:
	_window = get_tree().root
	load_settings()
	apply_all_settings()

# ===== 加载/保存 =====
func load_settings() -> void:
	if not FileAccess.file_exists(settings_path):
		return
	
	var file = FileAccess.open(settings_path, FileAccess.READ)
	if not file:
		return
	
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	
	if not data is Dictionary:
		return
	
	# 画面
	if data.has("resolution"):
		var res = data["resolution"]
		resolution = Vector2i(res[0], res[1])
	window_mode = data.get("window_mode", window_mode)
	brightness = data.get("brightness", brightness)
	contrast = data.get("contrast", contrast)
	gamma = data.get("gamma", gamma)
	saturation = data.get("saturation", saturation)
	show_fps = data.get("show_fps", show_fps)
	show_perf_monitor = data.get("show_perf_monitor", show_perf_monitor)
	vsync_mode = data.get("vsync_mode", vsync_mode)
	
	# 声音
	master_volume = data.get("master_volume", master_volume)
	bgm_volume = data.get("bgm_volume", bgm_volume)
	sfx_volume = data.get("sfx_volume", sfx_volume)
	
	# 操作
	if data.has("key_bindings"):
		key_bindings = data["key_bindings"]
	
	# 辅助
	colorblind_mode = data.get("colorblind_mode", colorblind_mode)
	text_size = data.get("text_size", text_size)
	ui_scale = data.get("ui_scale", ui_scale)
	
	# 其他
	language = data.get("language", language)

func save_settings() -> void:
	var data = {
		# 画面
		"resolution": [resolution.x, resolution.y],
		"window_mode": window_mode,
		"brightness": brightness,
		"contrast": contrast,
		"gamma": gamma,
		"saturation": saturation,
		"show_fps": show_fps,
		"show_perf_monitor": show_perf_monitor,
		"vsync_mode": vsync_mode,
		# 声音
		"master_volume": master_volume,
		"bgm_volume": bgm_volume,
		"sfx_volume": sfx_volume,
		# 操作
		"key_bindings": key_bindings,
		# 辅助
		"colorblind_mode": colorblind_mode,
		"text_size": text_size,
		"ui_scale": ui_scale,
		# 其他
		"language": language
	}
	
	var file = FileAccess.open(settings_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "  "))
		file.close()

# ===== 应用设置 =====
func apply_all_settings() -> void:
	apply_window_mode()
	apply_resolution()
	apply_vsync()
	apply_audio_settings()
	apply_ui_scale()
	# 后处理效果由 PostProcess 节点自行监听设置变化

func apply_vsync() -> void:
	match vsync_mode:
		0:  # 禁用
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		1:  # 启用
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		2:  # 自适应
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)

func apply_window_mode() -> void:
	if not _window:
		_window = get_tree().root
	
	match window_mode:
		0:  # 窗口
			_window.mode = Window.MODE_WINDOWED
			_window.borderless = false
		1:  # 全屏
			_window.mode = Window.MODE_FULLSCREEN
			_window.borderless = false
		2:  # 无边框全屏
			_window.mode = Window.MODE_FULLSCREEN
			_window.borderless = true

func apply_resolution() -> void:
	if window_mode != 0:  # 仅窗口模式可调整分辨率
		return
	if not _window:
		_window = get_tree().root
	
	_window.size = resolution
	_window.move_to_center()

func apply_audio_settings() -> void:
	# 音频总线设置
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(master_volume))
	
	var bgm_bus = AudioServer.get_bus_index("BGM")
	if bgm_bus >= 0:
		AudioServer.set_bus_volume_db(bgm_bus, linear_to_db(bgm_volume))
	
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume))

func apply_ui_scale() -> void:
	# UI缩放由各界面自行处理
	emit_signal("settings_changed", "ui_scale", ui_scale)

# ===== 设置修改接口 =====
func set_resolution(value: Vector2i) -> void:
	resolution = value
	apply_resolution()
	save_settings()
	emit_signal("settings_changed", "resolution", value)

func set_window_mode(value: int) -> void:
	window_mode = value
	apply_window_mode()
	save_settings()
	emit_signal("settings_changed", "window_mode", value)

func set_brightness(value: float) -> void:
	brightness = clamp(value, 0.5, 1.5)
	save_settings()
	emit_signal("settings_changed", "brightness", brightness)

func set_contrast(value: float) -> void:
	contrast = clamp(value, 0.5, 1.5)
	save_settings()
	emit_signal("settings_changed", "contrast", contrast)

func set_gamma(value: float) -> void:
	gamma = clamp(value, 0.5, 1.5)
	save_settings()
	emit_signal("settings_changed", "gamma", gamma)

func set_saturation(value: float) -> void:
	saturation = clamp(value, 0.0, 2.0)
	save_settings()
	emit_signal("settings_changed", "saturation", saturation)

func set_show_fps(value: bool) -> void:
	show_fps = value
	save_settings()
	emit_signal("settings_changed", "show_fps", value)

func set_show_perf_monitor(value: bool) -> void:
	show_perf_monitor = value
	save_settings()
	emit_signal("settings_changed", "show_perf_monitor", value)

func set_vsync_mode(value: int) -> void:
	vsync_mode = value
	apply_vsync()
	save_settings()
	emit_signal("settings_changed", "vsync_mode", value)

func set_master_volume(value: float) -> void:
	master_volume = clamp(value, 0.0, 1.0)
	apply_audio_settings()
	save_settings()
	emit_signal("settings_changed", "master_volume", master_volume)

func set_bgm_volume(value: float) -> void:
	bgm_volume = clamp(value, 0.0, 1.0)
	apply_audio_settings()
	save_settings()
	emit_signal("settings_changed", "bgm_volume", bgm_volume)

func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	apply_audio_settings()
	save_settings()
	emit_signal("settings_changed", "sfx_volume", sfx_volume)

func set_key_binding(action: String, index: int, key: int) -> void:
	if key_bindings.has(action):
		key_bindings[action][index] = key
		save_settings()
		emit_signal("settings_changed", "key_bindings", key_bindings)

func set_colorblind_mode(value: int) -> void:
	colorblind_mode = value
	save_settings()
	emit_signal("settings_changed", "colorblind_mode", value)

func set_text_size(value: int) -> void:
	text_size = value
	save_settings()
	emit_signal("settings_changed", "text_size", value)

func set_ui_scale(value: float) -> void:
	ui_scale = clamp(value, 0.75, 1.5)
	apply_ui_scale()
	save_settings()

func set_language(value: int) -> void:
	language = value
	save_settings()
	emit_signal("settings_changed", "language", value)

# ===== 辅助函数 =====
func get_text_size_multiplier() -> float:
	match text_size:
		0: return 0.85
		1: return 1.0
		2: return 1.25
	return 1.0

func get_key_name(key: int) -> String:
	if key == KEY_SPACE:
		return "Space"
	elif key == KEY_ENTER:
		return "Enter"
	elif key == KEY_ESCAPE:
		return "Esc"
	elif key == KEY_LEFT:
		return "←"
	elif key == KEY_RIGHT:
		return "→"
	elif key == KEY_UP:
		return "↑"
	elif key == KEY_DOWN:
		return "↓"
	else:
		return OS.get_keycode_string(key)

func get_resolution_options() -> Array:
	# 获取当前显示器支持的分辨率
	var screen_id = DisplayServer.get_primary_screen()
	var modes = []
	
	# 添加常用分辨率
	var common_resolutions = [
		Vector2i(1280, 720),
		Vector2i(1366, 768),
		Vector2i(1600, 900),
		Vector2i(1920, 1080),
		Vector2i(2560, 1440),
		Vector2i(3840, 2160)
	]
	
	# 尝试获取显示器支持的模式
	for i in range(DisplayServer.get_screen_count()):
		var screen_size = DisplayServer.screen_get_size(i)
		if screen_size.x > 0 and screen_size.y > 0:
			# 添加当前屏幕分辨率
			if not modes.has(screen_size):
				modes.append(screen_size)
	
	# 添加常用分辨率（如果小于当前屏幕）
	var max_size = DisplayServer.screen_get_size(screen_id)
	for res in common_resolutions:
		if res.x <= max_size.x and res.y <= max_size.y:
			if not modes.has(res):
				modes.append(res)
	
	# 按宽度排序
	modes.sort_custom(func(a, b): return a.x < b.x)
	
	# 如果没有获取到任何分辨率，返回默认列表
	if modes.is_empty():
		return common_resolutions
	
	return modes

func get_resolution_index() -> int:
	var options = get_resolution_options()
	for i in range(options.size()):
		if options[i] == resolution:
			return i
	return 3  # 默认1920x1080
