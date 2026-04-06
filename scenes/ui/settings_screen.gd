extends Control

# ===== 设置界面 =====
enum Tab { GRAPHICS, AUDIO, CONTROLS, ACCESSIBILITY, OTHER }

var current_tab: int = Tab.GRAPHICS

# 页面节点
@onready var tab_buttons: HBoxContainer = $Panel/MarginContainer/VBoxContainer/TabBar
@onready var content_container: Control = $Panel/MarginContainer/VBoxContainer/ContentContainer

@onready var graphics_page: Control = content_container.get_node("GraphicsPage")
@onready var audio_page: Control = content_container.get_node("AudioPage")
@onready var controls_page: Control = content_container.get_node("ControlsPage")
@onready var accessibility_page: Control = content_container.get_node("AccessibilityPage")
@onready var other_page: Control = content_container.get_node("OtherPage")

# 按键绑定状态
var waiting_for_key: bool = false
var waiting_action: String = ""
var waiting_index: int = 0

func _ready() -> void:
	_init_options()
	_connect_signals()
	_connect_sliders()
	_load_current_settings()

# 初始化下拉选项
func _init_options() -> void:
	# 分辨率选项
	var res_option: OptionButton = graphics_page.find_child("ResolutionOption", true, false)
	if res_option:
		res_option.clear()
		for res in SettingsManager.get_resolution_options():
			res_option.add_item("%d × %d" % [res.x, res.y])
	
	# 窗口模式选项
	var mode_option: OptionButton = graphics_page.find_child("WindowModeOption", true, false)
	if mode_option:
		mode_option.clear()
		mode_option.add_item("窗口")
		mode_option.add_item("全屏")
		mode_option.add_item("无边框全屏")
	
	# VSync 选项
	var vsync_option: OptionButton = graphics_page.find_child("VSyncOption", true, false)
	if vsync_option:
		vsync_option.clear()
		vsync_option.add_item("禁用")
		vsync_option.add_item("启用")
		vsync_option.add_item("自适应")
	
	# 色盲模式选项
	var colorblind_option: OptionButton = accessibility_page.find_child("ColorblindOption", true, false)
	if colorblind_option:
		colorblind_option.clear()
		colorblind_option.add_item("无")
		colorblind_option.add_item("红绿色盲")
		colorblind_option.add_item("蓝黄色盲")
		colorblind_option.add_item("全色盲")
	
	# 文字大小选项
	var textsize_option: OptionButton = accessibility_page.find_child("TextSizeOption", true, false)
	if textsize_option:
		textsize_option.clear()
		textsize_option.add_item("小")
		textsize_option.add_item("中")
		textsize_option.add_item("大")
	
	# 语言选项
	var lang_option: OptionButton = other_page.find_child("LanguageOption", true, false)
	if lang_option:
		lang_option.clear()
		lang_option.add_item("中文")
		lang_option.add_item("English")

# 连接滑块信号
func _connect_sliders() -> void:
	# 滑块配置列表
	var sliders: Array = [
		["BrightnessSlider", graphics_page],
		["ContrastSlider", graphics_page],
		["GammaSlider", graphics_page],
		["SaturationSlider", graphics_page],
		["MasterSlider", audio_page],
		["BGMSlider", audio_page],
		["SFXSlider", audio_page],
		["UIScaleSlider", accessibility_page]
	]
	
	for slider_info in sliders:
		var slider_name: String = slider_info[0]
		var parent: Control = slider_info[1]
		var slider: HSlider = parent.find_child(slider_name, true, false)
		if slider:
			slider.value_changed.connect(_on_slider_changed.bind(slider))

# 连接所有UI信号
func _connect_signals() -> void:
	# 标签页按钮
	for i in range(tab_buttons.get_child_count()):
		var btn: Button = tab_buttons.get_child(i)
		btn.pressed.connect(_on_tab_pressed.bind(i))
	
	# 返回按钮
	var back_btn: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/BackButton
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)
	
	# 应用按钮
	var apply_btn: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/ApplyButton
	if apply_btn:
		apply_btn.pressed.connect(_on_apply_pressed)
	
	# 按键绑定按钮
	_connect_key_buttons()

# 切换标签页
func _on_tab_pressed(index: int) -> void:
	current_tab = index
	_show_tab(index)

# 显示对应标签页
func _show_tab(tab: int) -> void:
	# 隐藏所有页面
	graphics_page.visible = false
	audio_page.visible = false
	controls_page.visible = false
	accessibility_page.visible = false
	other_page.visible = false
	
	# 显示选中页面
	match tab:
		Tab.GRAPHICS: graphics_page.visible = true
		Tab.AUDIO: audio_page.visible = true
		Tab.CONTROLS: controls_page.visible = true
		Tab.ACCESSIBILITY: accessibility_page.visible = true
		Tab.OTHER: other_page.visible = true
	
	# 更新按钮选中状态
	for i in range(tab_buttons.get_child_count()):
		var btn: Button = tab_buttons.get_child(i)
		btn.button_pressed = (i == tab)

# 加载当前设置到UI
func _load_current_settings() -> void:
	var sm := SettingsManager
	
	# ==================== 画面设置 ====================
	var res_option: OptionButton = graphics_page.find_child("ResolutionOption", true, false)
	if res_option: res_option.selected = sm.get_resolution_index()
	
	var mode_option: OptionButton = graphics_page.find_child("WindowModeOption", true, false)
	if mode_option: mode_option.selected = sm.window_mode
	
	var brightness_slider: HSlider = graphics_page.find_child("BrightnessSlider", true, false)
	if brightness_slider: brightness_slider.value = sm.brightness
	
	var contrast_slider: HSlider = graphics_page.find_child("ContrastSlider", true, false)
	if contrast_slider: contrast_slider.value = sm.contrast
	
	var gamma_slider: HSlider = graphics_page.find_child("GammaSlider", true, false)
	if gamma_slider: gamma_slider.value = sm.gamma
	
	var saturation_slider: HSlider = graphics_page.find_child("SaturationSlider", true, false)
	if saturation_slider: saturation_slider.value = sm.saturation
	
	# 修复：CheckButton → CheckBox
	var fps_check: CheckBox = graphics_page.find_child("FPSCheck", true, false)
	if fps_check: fps_check.button_pressed = sm.show_fps
	
	# 修复：CheckButton → CheckBox
	var perf_check: CheckBox = graphics_page.find_child("PerfCheck", true, false)
	if perf_check: perf_check.button_pressed = sm.show_perf_monitor
	
	var vsync_option: OptionButton = graphics_page.find_child("VSyncOption", true, false)
	if vsync_option: vsync_option.selected = sm.vsync_mode
	
	# ==================== 声音设置 ====================
	var master_slider: HSlider = audio_page.find_child("MasterSlider", true, false)
	if master_slider: master_slider.value = sm.master_volume
	
	var bgm_slider: HSlider = audio_page.find_child("BGMSlider", true, false)
	if bgm_slider: bgm_slider.value = sm.bgm_volume
	
	var sfx_slider: HSlider = audio_page.find_child("SFXSlider", true, false)
	if sfx_slider: sfx_slider.value = sm.sfx_volume
	
	# ==================== 操作设置 ====================
	_update_key_bindings()
	
	# ==================== 辅助设置 ====================
	var colorblind_option: OptionButton = accessibility_page.find_child("ColorblindOption", true, false)
	if colorblind_option: colorblind_option.selected = sm.colorblind_mode
	
	var textsize_option: OptionButton = accessibility_page.find_child("TextSizeOption", true, false)
	if textsize_option: textsize_option.selected = sm.text_size
	
	var uiscale_slider: HSlider = accessibility_page.find_child("UIScaleSlider", true, false)
	if uiscale_slider: uiscale_slider.value = sm.ui_scale
	
	# ==================== 其他设置 ====================
	var lang_option: OptionButton = other_page.find_child("LanguageOption", true, false)
	if lang_option: lang_option.selected = sm.language

# Godot 4 兼容版驼峰命名转换（move_left → MoveLeft）
func _to_pascal_case(s: String) -> String:
	var parts: PackedStringArray = s.split("_")
	var result: String = ""
	for part in parts:
		result += part.capitalize()
	return result

# 更新按键绑定显示文本
func _update_key_bindings() -> void:
	var sm := SettingsManager
	var actions: Array = ["move_left", "move_right", "grab", "pause"]
	
	for action in actions:
		var pascal_name: String = _to_pascal_case(action)
		# 获取两个按键按钮
		var btn1: Button = controls_page.find_child("%sKey1" % pascal_name, true, false)
		var btn2: Button = controls_page.find_child("%sKey2" % pascal_name, true, false)
		
		var keys: Array = sm.key_bindings.get(action, [0, 0])
		# 空按键显示"未设置"
		if btn1: btn1.text = _get_safe_key_name(keys[0])
		if btn2: btn2.text = _get_safe_key_name(keys[1])

# 安全获取按键名称（处理无效按键）
func _get_safe_key_name(key: int) -> String:
	if key == 0:
		return "未设置"
	return SettingsManager.get_key_name(key)

# 返回主菜单
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

# 应用所有设置
func _on_apply_pressed() -> void:
	var sm := SettingsManager
	
	# ==================== 画面设置 ====================
	var res_option: OptionButton = graphics_page.find_child("ResolutionOption", true, false)
	if res_option: sm.set_resolution(sm.get_resolution_options()[res_option.selected])
	
	var mode_option: OptionButton = graphics_page.find_child("WindowModeOption", true, false)
	if mode_option: sm.set_window_mode(mode_option.selected)
	
	var brightness_slider: HSlider = graphics_page.find_child("BrightnessSlider", true, false)
	if brightness_slider: sm.set_brightness(brightness_slider.value)
	
	var contrast_slider: HSlider = graphics_page.find_child("ContrastSlider", true, false)
	if contrast_slider: sm.set_contrast(contrast_slider.value)
	
	var gamma_slider: HSlider = graphics_page.find_child("GammaSlider", true, false)
	if gamma_slider: sm.set_gamma(gamma_slider.value)
	
	var saturation_slider: HSlider = graphics_page.find_child("SaturationSlider", true, false)
	if saturation_slider: sm.set_saturation(saturation_slider.value)
	
	# 修复：CheckButton → CheckBox
	var fps_check: CheckBox = graphics_page.find_child("FPSCheck", true, false)
	if fps_check: sm.set_show_fps(fps_check.button_pressed)
	
	# 修复：CheckButton → CheckBox
	var perf_check: CheckBox = graphics_page.find_child("PerfCheck", true, false)
	if perf_check: sm.set_show_perf_monitor(perf_check.button_pressed)
	
	var vsync_option: OptionButton = graphics_page.find_child("VSyncOption", true, false)
	if vsync_option: sm.set_vsync_mode(vsync_option.selected)
	
	# ==================== 声音设置 ====================
	var master_slider: HSlider = audio_page.find_child("MasterSlider", true, false)
	if master_slider: sm.set_master_volume(master_slider.value)
	
	var bgm_slider: HSlider = audio_page.find_child("BGMSlider", true, false)
	if bgm_slider: sm.set_bgm_volume(bgm_slider.value)
	
	var sfx_slider: HSlider = audio_page.find_child("SFXSlider", true, false)
	if sfx_slider: sm.set_sfx_volume(sfx_slider.value)
	
	# ==================== 辅助设置 ====================
	var colorblind_option: OptionButton = accessibility_page.find_child("ColorblindOption", true, false)
	if colorblind_option: sm.set_colorblind_mode(colorblind_option.selected)
	
	var textsize_option: OptionButton = accessibility_page.find_child("TextSizeOption", true, false)
	if textsize_option: sm.set_text_size(textsize_option.selected)
	
	var uiscale_slider: HSlider = accessibility_page.find_child("UIScaleSlider", true, false)
	if uiscale_slider: sm.set_ui_scale(uiscale_slider.value)
	
	# ==================== 其他设置 ====================
	var lang_option: OptionButton = other_page.find_child("LanguageOption", true, false)
	if lang_option: sm.set_language(lang_option.selected)

# 请求绑定按键
func _on_key_bind_requested(action: String, index: int) -> void:
	waiting_for_key = true
	waiting_action = action
	waiting_index = index
	
	# 显示提示
	var label: Label = controls_page.find_child("WaitingLabel", true, false)
	if label:
		label.text = "请按下新的按键（ESC取消）"
		label.visible = true

# 输入监听（绑定按键）
func _input(event: InputEvent) -> void:
	if not waiting_for_key:
		return
	
	# 仅监听按键按下事件
	if event is InputEventKey and event.pressed:
		var key: int = event.keycode
		# ESC取消绑定
		if key == KEY_ESCAPE:
			_reset_key_binding_ui()
			return
		
		# 设置新按键
		SettingsManager.set_key_binding(waiting_action, waiting_index, key)
		_reset_key_binding_ui()
		_update_key_bindings()
		
		# 拦截输入，防止触发其他操作
		get_viewport().set_input_as_handled()

# 重置按键绑定UI状态
func _reset_key_binding_ui() -> void:
	waiting_for_key = false
	var label: Label = controls_page.find_child("WaitingLabel", true, false)
	if label:
		label.visible = false

# 连接按键绑定按钮信号
func _connect_key_buttons() -> void:
	# 正确的驼峰节点名称
	var key_buttons: Array = [
		["move_left", 0, "MoveLeftKey1"],
		["move_left", 1, "MoveLeftKey2"],
		["move_right", 0, "MoveRightKey1"],
		["move_right", 1, "MoveRightKey2"],
		["grab", 0, "GrabKey1"],
		["grab", 1, "GrabKey2"],
		["pause", 0, "PauseKey1"],
		["pause", 1, "PauseKey2"]
	]
	
	for btn_info in key_buttons:
		var action: String = btn_info[0]
		var index: int = btn_info[1]
		var btn_name: String = btn_info[2]
		var btn: Button = controls_page.find_child(btn_name, true, false)
		if btn:
			btn.pressed.connect(_on_key_bind_requested.bind(action, index))

# 滑块值变化
func _on_slider_changed(value: float, slider: HSlider) -> void:
	var parent: Node = slider.get_parent()
	if parent and parent.find_child("Value", true, false):
		var label: Label = parent.find_child("Value", true, false)
		label.text = "%d%%" % int(value * 100)
