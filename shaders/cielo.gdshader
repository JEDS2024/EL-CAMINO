// Cielo de El Camino: degradado, sol o luna, estrellas que titilan y nubes que avanzan.
shader_type sky;

uniform vec3 arriba : source_color = vec3(0.1, 0.2, 0.5);
uniform vec3 horizonte : source_color = vec3(0.9, 0.7, 0.5);
uniform vec3 suelo : source_color = vec3(0.05, 0.04, 0.08);
uniform vec3 dir_astro = vec3(0.3, 0.6, 0.4);  // hacia el sol o la luna
uniform vec3 color_astro : source_color = vec3(1.0, 0.95, 0.8);
uniform float tam_astro = 0.045;
uniform float es_luna = 0.0;
uniform float estrellas = 0.0;
uniform float nubes = 0.5;
uniform vec3 color_nube : source_color = vec3(1.0, 0.96, 0.92);
uniform vec3 sombra_nube : source_color = vec3(0.7, 0.65, 0.75);
uniform float velocidad = 0.006;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int k = 0; k < 4; k++) {
		v += a * ruido(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = d.y;
	vec3 col = h >= 0.0 ? mix(horizonte, arriba, pow(clamp(h, 0.0, 1.0), 0.55)) : mix(horizonte, suelo, pow(clamp(-h * 3.0, 0.0, 1.0), 0.5));

	// estrellas (solo de noche)
	if (estrellas > 0.0 && h > 0.02) {
		vec2 uv = d.xz / (d.y + 0.25) * 70.0;
		vec2 celda = floor(uv);
		float r = hash(celda);
		if (r > 0.985) {
			float brillo = 0.6 + 0.4 * sin(TIME * (1.5 + r * 4.0) + r * 50.0);
			float punto = 1.0 - smoothstep(0.0, 0.35, length(fract(uv) - 0.5));
			col += vec3(0.9, 0.92, 1.0) * punto * brillo * estrellas * smoothstep(0.02, 0.25, h);
		}
	}

	// sol o luna
	vec3 a = normalize(dir_astro);
	float c = dot(d, a);
	float disco = smoothstep(cos(tam_astro), cos(tam_astro * 0.85), c);
	float halo = pow(max(c, 0.0), es_luna > 0.5 ? 180.0 : 24.0) * (es_luna > 0.5 ? 0.25 : 0.55);
	col += color_astro * halo;
	col = mix(col, color_astro, disco);

	// nubes: ruido proyectado sobre un plano alto, que avanza con el tiempo
	if (nubes > 0.0 && h > 0.0) {
		vec2 p = d.xz / (h + 0.12) * 1.4 + vec2(TIME * velocidad, TIME * velocidad * 0.4);
		float n = fbm(p);
		float cubierta = smoothstep(0.62 - nubes * 0.3, 0.82 - nubes * 0.25, n);
		float relieve = smoothstep(0.4, 0.9, fbm(p * 1.7 + 3.1));
		vec3 cn = mix(sombra_nube, color_nube, relieve);
		cn += color_astro * pow(max(c, 0.0), 6.0) * 0.35;
		col = mix(col, cn, cubierta * smoothstep(0.0, 0.18, h));
	}
	COLOR = col;
}
