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



// Adapted from "Nebula 3" by @XorDev - https://x.com/XorDev/status/1918766627828515190
// Iteration count reduced (100 -> 40) for use as a per-frame transition.
vec3 nebula1Effect(vec2 I, vec2 res, float t) {
    vec4 O = vec4(0.0);
    float i = 0.0, z = 0.0, d, s;
    for (; i++ < 40.0; ) {
        vec3 p = z * normalize(vec3(I + I, 0.0) - vec3(res, res.y));
        p.z -= t;
        for (d = 1.0; d < 64.0; d += d)
            p += 0.7 * cos(p.yzx * d) / d;
        p.xy *= mat2(cos(z * 0.2 + vec4(0.0, 11.0, 33.0, 0.0)));
        z += d = 0.03 + 0.1 * max(s = 3.0 - abs(p.x), -s * 0.2);
        O += (cos(s + s - vec4(5.0, 0.0, 1.0, 3.0)) + 1.4) / d / z;
    }
    O = tanh(O * O / 1.6e5);
    return O.rgb;
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
    vec2 res = max(surface_size, vec2(1.0));

    float t = p * 4.0 + seed_local;

    vec3 col = clamp(nebula1Effect(uv * res, res, t), 0.0, 4.0);
    float energy = clamp(dot(col, vec3(0.299, 0.587, 0.114)), 0.0, 1.0);

    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));

    float appear = (1.0 - dist * 1.2) + (1.0 - energy) * 0.7;
    float reveal = smoothstep(appear + 0.5, appear - 0.5, (1.0 - p) * 1.8);

    vec2 warp_r = clamp(vec2(dFdx(energy), dFdy(energy)) * 30.0 + 0.5, 0.0, 1.0);
    float distort_strength = (1.0 - p) * (1.0 - p) * 0.35;
    vec2 warped_uv = uv + (warp_r - 0.5) * distort_strength;

    vec4 screen = texture(tex, warped_uv);

    float edge = smoothstep(0.0, 0.6, reveal) * smoothstep(1.0, 0.4, reveal);
    vec3 final_rgb = mix(screen.rgb, col, edge * 0.9);

    fragColor = vec4(final_rgb, screen.a) * reveal;

}
