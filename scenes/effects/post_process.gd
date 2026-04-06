extends CanvasLayer

# ===== 画面后处理效果 =====
# 使用 BackBufferCopy + ColorRect 实现亮度/对比度/伽马/饱和度调整

var _color_rect: ColorRect
var _back_buffer: BackBufferCopy
var _initialized: bool = false

func _ready() -> void:
	await get_tree().process_frame
	_setup_if_needed()
	SettingsManager.settings_changed.connect(_on_settings_changed)

func _setup_if_needed() -> void:
	if _initialized:
		return
	
	# 检查是否需要后处理（任何参数不是默认值）
	if not _needs_post_process():
		return
	
	# 创建 BackBufferCopy 捕获屏幕内容
	_back_buffer = BackBufferCopy.new()
	_back_buffer.rect = Rect2(0, 0, 100000, 100000)  # 覆盖整个屏幕
	add_child(_back_buffer)
	
	# 创建全屏 ColorRect 应用着色器
	_color_rect = ColorRect.new()
	_color_rect.name = "PostProcessEffect"
	_color_rect.color = Color.WHITE
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 加载并设置着色器
	var shader = load("res://shaders/post_process.gdshader")
	if shader:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("brightness", SettingsManager.brightness)
		mat.set_shader_parameter("contrast", SettingsManager.contrast)
		mat.set_shader_parameter("gamma", SettingsManager.gamma)
		mat.set_shader_parameter("saturation", SettingsManager.saturation)
		_color_rect.material = mat
	
	add_child(_color_rect)
	_initialized = true
	
	print("【画面后处理】已启用")

func _needs_post_process() -> bool:
	return (
		abs(SettingsManager.brightness - 1.0) > 0.01 or
		abs(SettingsManager.contrast - 1.0) > 0.01 or
		abs(SettingsManager.gamma - 1.0) > 0.01 or
		abs(SettingsManager.saturation - 1.0) > 0.01
	)

func _on_settings_changed(setting_name: String, _value) -> void:
	if not _initialized:
		_setup_if_needed()
		return
	
	if not _color_rect or not _color_rect.material:
		return
	
	var mat = _color_rect.material as ShaderMaterial
	
	match setting_name:
		"brightness":
			mat.set_shader_parameter("brightness", SettingsManager.brightness)
		"contrast":
			mat.set_shader_parameter("contrast", SettingsManager.contrast)
		"gamma":
			mat.set_shader_parameter("gamma", SettingsManager.gamma)
		"saturation":
			mat.set_shader_parameter("saturation", SettingsManager.saturation)

# 强制刷新后处理
func refresh() -> void:
	if _initialized and _color_rect and _color_rect.material:
		var mat = _color_rect.material as ShaderMaterial
		mat.set_shader_parameter("brightness", SettingsManager.brightness)
		mat.set_shader_parameter("contrast", SettingsManager.contrast)
		mat.set_shader_parameter("gamma", SettingsManager.gamma)
		mat.set_shader_parameter("saturation", SettingsManager.saturation)