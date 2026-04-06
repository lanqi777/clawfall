extends CanvasLayer

# ===== 性能监控显示 =====

@onready var fps_label: Label = $Panel/VBox/FPSLabel
@onready var perf_label: Label = $Panel/VBox/PerfLabel

var update_timer: float = 0.0
var update_interval: float = 0.5  # 每0.5秒更新一次

# 性能数据
var fps_history: Array = []
var max_history: int = 60

func _ready() -> void:
	# 初始隐藏，根据设置决定是否显示
	visible = false
	await get_tree().process_frame
	_update_visibility()

func _process(delta: float) -> void:
	_update_visibility()
	
	if not visible:
		return
	
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		_update_display()

func _update_visibility() -> void:
	var show_fps = SettingsManager.show_fps
	var show_perf = SettingsManager.show_perf_monitor
	
	visible = show_fps or show_perf
	
	if fps_label:
		fps_label.visible = show_fps
	if perf_label:
		perf_label.visible = show_perf

func _update_display() -> void:
	var fps = Engine.get_frames_per_second()
	fps_history.append(fps)
	if fps_history.size() > max_history:
		fps_history.pop_front()
	
	# FPS 显示
	if fps_label and fps_label.visible:
		var avg_fps = _get_average_fps()
		var min_fps = fps_history.min() if fps_history.size() > 0 else 0
		var max_fps = fps_history.max() if fps_history.size() > 0 else 0
		fps_label.text = "FPS: %d (avg: %d, min: %d, max: %d)" % [fps, avg_fps, min_fps, max_fps]
		
		# 根据FPS变色
		if fps >= 55:
			fps_label.add_theme_color_override("font_color", Color.GREEN)
		elif fps >= 30:
			fps_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			fps_label.add_theme_color_override("font_color", Color.RED)
	
	# 性能监控显示
	if perf_label and perf_label.visible:
		var memory = OS.get_memory_info()
		var static_mem = memory.get("static", 0) / (1024 * 1024)
		var dynamic_mem = memory.get("dynamic", 0) / (1024 * 1024)
		var total_mem = (static_mem + dynamic_mem)
		
		var draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		var objects = Performance.get_monitor(Performance.OBJECT_COUNT)
		var nodes = Performance.get_monitor(Performance.NODE_COUNT)
		
		perf_label.text = """内存: %.1f MB
Draw Calls: %d
对象数: %d
节点数: %d""" % [total_mem, draw_calls, objects, nodes]

func _get_average_fps() -> int:
	if fps_history.size() == 0:
		return 0
	var sum = 0
	for fps in fps_history:
		sum += fps
	return int(sum / fps_history.size())