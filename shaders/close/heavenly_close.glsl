#version 320 es
// @duration 0.5
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;
uniform vec2 resolution;

// Adapted from "Heavenly" by @XorDev
// Iteration count reduced (100 -> 40) for use as a per-frame transition.
vec3 heavenlyEffect(vec2 I, vec2 res, float t) {
    vec4 O = vec4(0.0);
    float i = 0.0, z = 0.0, d;
    for (; i++ < 40.0; ) {
        vec3 p = z * normalize(vec3(I + I, 0.0) - vec3(res, res.y));
        p.z -= t;
        for (d = 1.0; d < 9.0; d /= 0.7)
            p += cos(p.yzx * d + z * 0.2) / d;
        z += d = 0.02 + 0.1 * abs(3.0 - length(p.xy));
        O += (cos(z + t + vec4(6.0, 1.0, 2.0, 3.0)) + 1.0) / d;
    }
    O = tanh(O / 1200.0);
    return O.rgb;
}

void main() {
    float p = progress;
    vec2 uv = v_texcoord;
    float seed_local = seed * 100.0;
    vec2 res = surface_size.x > 1.0 ? surface_size : (resolution.x > 1.0 ? resolution : vec2(1920.0, 1080.0));

    float t = p * 4.0 + seed_local;

    vec3 col = clamp(heavenlyEffect(uv * res, res, t), 0.0, 4.0);
    float energy = clamp(dot(col, vec3(0.299, 0.587, 0.114)), 0.0, 1.0);

    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));

    float dissolve = (1.0 - dist) * 0.9 + energy * 0.4;
    float remain = smoothstep(dissolve + 0.3, dissolve - 0.3, p * 1.35);

    vec2 warp_r = clamp(vec2(dFdx(energy), dFdy(energy)) * 30.0 + 0.5, 0.0, 1.0);
    float distort_strength = p * p * 0.4;
    vec2 warped_uv = uv + (warp_r - 0.5) * distort_strength;

    vec4 screen = texture(tex, warped_uv);

    float edge = smoothstep(0.0, 0.6, remain) * smoothstep(1.0, 0.4, remain);
    vec3 final_rgb = mix(screen.rgb, col, edge * 0.9);

    float tail = smoothstep(1.0, 0.85, p);
    float mask = screen.a * remain * tail;
    fragColor = vec4(final_rgb * mask, mask);
}
