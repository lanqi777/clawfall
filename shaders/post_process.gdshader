shader_type canvas_item;

// 画面后处理着色器
// 应用亮度、对比度、伽马、饱和度调整

uniform float brightness : hint_range(0.5, 1.5) = 1.0;
uniform float contrast : hint_range(0.5, 1.5) = 1.0;
uniform float gamma : hint_range(0.5, 1.5) = 1.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	// 获取屏幕颜色
	vec4 color = texture(TEXTURE, UV);
	
	// 1. 亮度调整
	color.rgb *= brightness;
	
	// 2. 对比度调整 (以0.5为中心)
	color.rgb = (color.rgb - 0.5) * contrast + 0.5;
	
	// 3. 伽马校正
	color.rgb = pow(max(color.rgb, vec3(0.001)), vec3(1.0 / gamma));
	
	// 4. 饱和度调整 (使用亮度作为基准)
	float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	color.rgb = mix(vec3(luminance), color.rgb, saturation);
	
	// 钳制到有效范围
	color.rgb = clamp(color.rgb, 0.0, 1.0);
	
	COLOR = color;
}