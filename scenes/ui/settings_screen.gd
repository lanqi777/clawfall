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

# 正在等待按键绑定
var waiting_for_key: bool = false
var waiting_action: String = ""
var waiting_index: int = 0

func _ready() -> void:
	_init_options()
	_connect_signals()
	_connect_sliders()
	_load_current_settings()
	_show_tab(Tab.GRAPHICS)

func _init_options() -> void:
	# 分辨率选项
	var res_option = graphics_page.get_node_or_null("ResolutionOption")
	if res_option:
		res_option.clear()
		for res in SettingsManager.get_resolution_options():
			res_option.add_item("%d × %d" % [res.x, res.y])
	
	# 窗口模式选项
	var mode_option = graphics_page.get_node_or_null("WindowModeOption")
	if mode_option:
		mode_option.clear()
		mode_option.add_item("窗口")
		mode_option.add_item("全屏")
		mode_option.add_item("无边框全屏")
	
	# VSync 选项
	var vsync_option = graphics_page.get_node_or_null("VSyncOption")
	if vsync_option:
		vsync_option.clear()
		vsync_option.add_item("禁用")
		vsync_option.add_item("启用")
		vsync_option.add_item("自适应")
	
	# 色盲模式选项
	var colorblind_option = accessibility_page.get_node_or_null("ColorblindOption")
	if colorblind_option:
		colorblind_option.clear()
		colorblind_option.add_item("无")
		colorblind_option.add_item("红绿色盲")
		colorblind_option.add_item("蓝黄色盲")
		colorblind_option.add_item("全色盲")
	
	# 文字大小选项
	var textsize_option = accessibility_page.get_node_or_null("TextSizeOption")
	if textsize_option:
		textsize_option.clear()
		textsize_option.add_item("小")
		textsize_option.add_item("中")
		textsize_option.add_item("大")
	
	# 语言选项
	var lang_option = other_page.get_node_or_null("LanguageOption")
	if lang_option:
		lang_option.clear()
		lang_option.add_item("中文")
		lang_option.add_item("English")

func _connect_sliders() -> void:
	# 连接滑块值变化信号，更新百分比显示
	var sliders = [
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
		var slider_name = slider_info[0]
		var parent = slider_info[1]
		var slider = parent.get_node_or_null(slider_name)
		if slider:
			slider.value_changed.connect(_on_slider_changed.bind(slider))

func _connect_signals() -> void:
	# 标签页按钮
	for i in range(tab_buttons.get_child_count()):
		var btn = tab_buttons.get_child(i)
		btn.pressed.connect(_on_tab_pressed.bind(i))
	
	# 返回按钮
	var back_btn = $Panel/MarginContainer/VBoxContainer/HBoxContainer/BackButton
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)
	
	# 应用按钮
	var apply_btn = $Panel/MarginContainer/VBoxContainer/HBoxContainer/ApplyButton
	if apply_btn:
		apply_btn.pressed.connect(_on_apply_pressed)
	
	# 按键绑定按钮
	_connect_key_buttons()

func _on_tab_pressed(index: int) -> void:
	current_tab = index
	_show_tab(index)

func _show_tab(tab: int) -> void:
	graphics_page.visible = (tab == Tab.GRAPHICS)
	audio_page.visible = (tab == Tab.AUDIO)
	controls_page.visible = (tab == Tab.CONTROLS)
	accessibility_page.visible = (tab == Tab.ACCESSIBILITY)
	other_page.visible = (tab == Tab.OTHER)
	
	# 更新标签按钮样式
	for i in range(tab_buttons.get_child_count()):
		var btn = tab_buttons.get_child(i)
		btn.button_pressed = (i == tab)

func _load_current_settings() -> void:
	var sm = SettingsManager
	
	# ===== 画面设置 =====
	var res_option = graphics_page.get_node_or_null("ResolutionOption")
	if res_option:
		res_option.selected = sm.get_resolution_index()
	
	var mode_option = graphics_page.get_node_or_null("WindowModeOption")
	if mode_option:
		mode_option.selected = sm.window_mode
	
	var brightness_slider = graphics_page.get_node_or_null("BrightnessSlider")
	if brightness_slider:
		brightness_slider.value = sm.brightness
	
	var contrast_slider = graphics_page.get_node_or_null("ContrastSlider")
	if contrast_slider:
		contrast_slider.value = sm.contrast
	
	var gamma_slider = graphics_page.get_node_or_null("GammaSlider")
	if gamma_slider:
		gamma_slider.value = sm.gamma
	
	var saturation_slider = graphics_page.get_node_or_null("SaturationSlider")
	if saturation_slider:
		saturation_slider.value = sm.saturation
	
	var fps_check = graphics_page.get_node_or_null("FPSCheck")
	if fps_check:
		fps_check.button_pressed = sm.show_fps
	
	var perf_check = graphics_page.get_node_or_null("PerfCheck")
	if perf_check:
		perf_check.button_pressed = sm.show_perf_monitor
	
	var vsync_option = graphics_page.get_node_or_null("VSyncOption")
	if vsync_option:
		vsync_option.selected = sm.vsync_mode
	
	# ===== 声音设置 =====
	var master_slider = audio_page.get_node_or_null("MasterSlider")
	if master_slider:
		master_slider.value = sm.master_volume
	
	var bgm_slider = audio_page.get_node_or_null("BGMSlider")
	if bgm_slider:
		bgm_slider.value = sm.bgm_volume
	
	var sfx_slider = audio_page.get_node_or_null("SFXSlider")
	if sfx_slider:
		sfx_slider.value = sm.sfx_volume
	
	# ===== 操作设置 =====
	_update_key_bindings()
	
	# ===== 辅助设置 =====
	var colorblind_option = accessibility_page.get_node_or_null("ColorblindOption")
	if colorblind_option:
		colorblind_option.selected = sm.colorblind_mode
	
	var textsize_option = accessibility_page.get_node_or_null("TextSizeOption")
	if textsize_option:
		textsize_option.selected = sm.text_size
	
	var uiscale_slider = accessibility_page.get_node_or_null("UIScaleSlider")
	if uiscale_slider:
		uiscale_slider.value = sm.ui_scale
	
	# ===== 其他设置 =====
	var lang_option = other_page.get_node_or_null("LanguageOption")
	if lang_option:
		lang_option.selected = sm.language

func _update_key_bindings() -> void:
	var sm = SettingsManager
	
	for action in ["move_left", "move_right", "grab", "pause"]:
		var btn1 = controls_page.get_node_or_null("%sKey1" % action.capitalize())
		var btn2 = controls_page.get_node_or_null("%sKey2" % action.capitalize())
		
		if btn1:
			var key = sm.key_bindings.get(action, [0, 0])[0]
			btn1.text = sm.get_key_name(key)
		if btn2:
			var key = sm.key_bindings.get(action, [0, 0])[1]
			btn2.text = sm.get_key_name(key)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_apply_pressed() -> void:
	var sm = SettingsManager
	
	# ===== 画面设置 =====
	var res_option = graphics_page.get_node_or_null("ResolutionOption")
	if res_option:
		sm.set_resolution(sm.get_resolution_options()[res_option.selected])
	
	var mode_option = graphics_page.get_node_or_null("WindowModeOption")
	if mode_option:
		sm.set_window_mode(mode_option.selected)
	
	var brightness_slider = graphics_page.get_node_or_null("BrightnessSlider")
	if brightness_slider:
		sm.set_brightness(brightness_slider.value)
	
	var contrast_slider = graphics_page.get_node_or_null("ContrastSlider")
	if contrast_slider:
		sm.set_contrast(contrast_slider.value)
	
	var gamma_slider = graphics_page.get_node_or_null("GammaSlider")
	if gamma_slider:
		sm.set_gamma(gamma_slider.value)
	
	var saturation_slider = graphics_page.get_node_or_null("SaturationSlider")
	if saturation_slider:
		sm.set_saturation(saturation_slider.value)
	
	var fps_check = graphics_page.get_node_or_null("FPSCheck")
	if fps_check:
		sm.set_show_fps(fps_check.button_pressed)
	
	var perf_check = graphics_page.get_node_or_null("PerfCheck")
	if perf_check:
		sm.set_show_perf_monitor(perf_check.button_pressed)
	
	var vsync_option = graphics_page.get_node_or_null("VSyncOption")
	if vsync_option:
		sm.set_vsync_mode(vsync_option.selected)
	
	# ===== 声音设置 =====
	var master_slider = audio_page.get_node_or_null("MasterSlider")
	if master_slider:
		sm.set_master_volume(master_slider.value)
	
	var bgm_slider = audio_page.get_node_or_null("BGMSlider")
	if bgm_slider:
		sm.set_bgm_volume(bgm_slider.value)
	
	var sfx_slider = audio_page.get_node_or_null("SFXSlider")
	if sfx_slider:
		sm.set_sfx_volume(sfx_slider.value)
	
	# ===== 辅助设置 =====
	var colorblind_option = accessibility_page.get_node_or_null("ColorblindOption")
	if colorblind_option:
		sm.set_colorblind_mode(colorblind_option.selected)
	
	var textsize_option = accessibility_page.get_node_or_null("TextSizeOption")
	if textsize_option:
		sm.set_text_size(textsize_option.selected)
	
	var uiscale_slider = accessibility_page.get_node_or_null("UIScaleSlider")
	if uiscale_slider:
		sm.set_ui_scale(uiscale_slider.value)
	
	# ===== 其他设置 =====
	var lang_option = other_page.get_node_or_null("LanguageOption")
	if lang_option:
		sm.set_language(lang_option.selected)

# ===== 按键绑定 =====
func _on_key_bind_requested(action: String, index: int) -> void:
	waiting_for_key = true
	waiting_action = action
	waiting_index = index
	
	# 显示提示
	var label = controls_page.get_node_or_null("WaitingLabel")
	if label:
		label.text = "请按下新的按键..."
		label.visible = true

func _input(event: InputEvent) -> void:
	if not waiting_for_key:
		return
	
	if event is InputEventKey and event.pressed:
		var key = event.keycode
		if key == KEY_ESCAPE:
			# 取消
			waiting_for_key = false
			var label = controls_page.get_node_or_null("WaitingLabel")
			if label:
				label.visible = false
			return
		
		# 设置新按键
		SettingsManager.set_key_binding(waiting_action, waiting_index, key)
		waiting_for_key = false
		
		# 更新显示
		_update_key_bindings()
		var label = controls_page.get_node_or_null("WaitingLabel")
		if label:
			label.visible = false
		
		get_viewport().set_input_as_handled()

func _connect_key_buttons() -> void:
	# 连接按键绑定按钮
	var key_buttons = [
		["move_left", 0, "Move_leftKey1"],
		["move_left", 1, "Move_leftKey2"],
		["move_right", 0, "Move_rightKey1"],
		["move_right", 1, "Move_rightKey2"],
		["grab", 0, "GrabKey1"],
		["grab", 1, "GrabKey2"],
		["pause", 0, "PauseKey1"],
		["pause", 1, "PauseKey2"]
	]
	
	for btn_info in key_buttons:
		var action = btn_info[0]
		var index = btn_info[1]
		var btn_name = btn_info[2]
		var btn = controls_page.get_node_or_null(btn_name)
		if btn:
			btn.pressed.connect(_on_key_bind_requested.bind(action, index))

func _on_slider_changed(value: float, slider: HSlider) -> void:
	# 更新百分比显示
	var parent = slider.get_parent()
	if parent and parent.has_node("Value"):
		var label = parent.get_node("Value")
		label.text = "%d%%" % int(value * 100)
