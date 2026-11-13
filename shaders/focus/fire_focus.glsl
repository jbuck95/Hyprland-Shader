#version 320 es
// @duration 0.45
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float time;
uniform float progress;
uniform float seed;
uniform vec2 surface_size;
uniform vec2 resolution;

precision highp float;



float rand(vec2 n) {
    return fract(cos(dot(n, vec2(2.9898, 20.1414))) * 5.5453);
}

float noise(vec2 n) {
    const vec2 d = vec2(0.0, 1.0);
    vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.000002), fract(n));
    return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

float fbm(vec2 n, float t) {
    float total = 0.0, amplitude = 2.5;
    for (int i = 0; i < 8; i++) {
        total += noise(n) * amplitude;
        n += n;
        float a = sin(t) * 0.07 + 0.49;
        amplitude *= a;
    }
    return total;
}

// fire field, returns an RGB color for a given uv/time; luminance of the
// result is used elsewhere as a noise-like scalar.
vec3 fire(vec2 p, float t) {
    const vec3 c1 = vec3(0.502, 0.1059, 0.1059);
    const vec3 c2 = vec3(167.0 / 255.0, 93.0 / 255.0, 110.0 / 255.0);
    const vec3 c3 = vec3(0.4902, 0.5333, 0.4902);
    const vec3 c4 = vec3(0.2118, 0.3451, 0.2706);
    const vec3 c5 = vec3(0.3176, 0.2549, 0.4);
    const vec3 c6 = vec3(0.8, 0.3569, 0.3569);

    float q = fbm(p - t * 0.07, t);
    vec2 r = vec2(fbm(p + q + t * -0.4 - p.x - p.y, t), fbm(p + q - t * 0.3, t));
    return mix(c1, c2, fbm(p + r, t)) + mix(c3, c4, r.x) - mix(c5, c6, r.y);
}


void main() {
    float _focus_p_raw = clamp(progress, 0.0, 1.0);
    float _focus_env = sin(_focus_p_raw * 3.14159265);

    if (_focus_env < 0.001) {
        fragColor = texture(tex, v_texcoord);
        return;
    }

    float _focus_progress = 1.0 - _focus_env * 0.85;



    float p = _focus_progress;
    vec2 uv = v_texcoord;
    float seed_local = seed * 100.0;

    float t = p * 6.0 + seed_local;

    vec3 fireCol = clamp(fire(uv * 4.0 + seed_local, t), 0.0, 1.0);
    float energy = dot(fireCol, vec3(0.299, 0.587, 0.114));

    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));

    float appear = (1.0 - dist * 1.2) + (1.0 - energy) * 0.7;
    float reveal = smoothstep(appear + 0.5, appear - 0.5, (1.0 - p) * 1.8);

    vec2 warp_r = vec2(
        energy,
        dot(clamp(fire(uv * 4.0 + seed_local + vec2(3.1, 1.9), t + 1.4), 0.0, 1.0), vec3(0.299, 0.587, 0.114))
    );

    float distort_strength = (1.0 - p) * (1.0 - p) * 0.35;
    vec2 warped_uv = uv + (warp_r - 0.5) * distort_strength;

    vec4 color = texture(tex, warped_uv);

    // fire-colored glow right at the reveal edge
    float edge = smoothstep(0.0, 0.6, reveal) * smoothstep(1.0, 0.4, reveal);
    vec3 final_rgb = mix(color.rgb, fireCol, edge * 0.9);

    fragColor = vec4(final_rgb, color.a) * reveal;

}
