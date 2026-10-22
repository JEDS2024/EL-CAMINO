// Árboles, arbustos y flores de El Camino: siempre de frente a la cámara (solo giran en Y)
// y se mecen con el viento; la parte de arriba se mueve más que la base.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform sampler2D textura : source_color, filter_nearest;
uniform float viento = 1.0;
uniform float flexible = 0.12;  // cuánto se dobla la punta (en metros)

void vertex() {
	vec3 eje_y = vec3(0.0, 1.0, 0.0);
	vec3 frente = normalize(vec3(INV_VIEW_MATRIX[2].x, 0.0, INV_VIEW_MATRIX[2].z));
	vec3 derecha = normalize(cross(eje_y, frente));
	vec3 escala = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(derecha * escala.x, 0.0), vec4(eje_y * escala.y, 0.0), vec4(frente * escala.z, 0.0), MODEL_MATRIX[3]);
	float altura = 1.0 - UV.y;  // 0 en la base, 1 en la punta
	float fase = MODEL_MATRIX[3].x * 0.37 + MODEL_MATRIX[3].z * 0.23;
	float vaiven = sin(TIME * 1.6 + fase) * 0.7 + sin(TIME * 2.9 + fase * 1.7) * 0.3;
	VERTEX.x += vaiven * flexible * viento * altura * altura;
}

void fragment() {
	vec4 c = texture(textura, UV);
	ALBEDO = c.rgb;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
