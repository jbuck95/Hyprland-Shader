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

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 4; i++) {
        v += amp * noise(p);
        p *= 2.0;
        amp *= 0.5;
    }
    return v;
}

vec2 warp_r;
float warpedFbm(vec2 p, float t) {
    vec2 q = vec2(fbm(p + vec2(0.0, 0.0)),
                  fbm(p + vec2(5.2, 1.3)));

    warp_r = vec2(fbm(p + 6.0 * q + vec2(1.7, 9.2) + 0.25 * t),
                  fbm(p + 6.0 * q + vec2(8.3, 2.8) + 0.22 * t));

    return fbm(p + 5.0 * warp_r);
}

void main() {
    float p = clamp(progress, 0.0, 1.0);
    // Sine envelope (0 -> 1 -> 0)
    float env = sin(p * 3.14159265);

    if (env < 0.001) {
        fragColor = texture(tex, v_texcoord);
        return;
    }

    vec2 uv = v_texcoord;
    float t = p * 6.0 + seed * 31.0;
    float fluid = warpedFbm(uv * 2.8, t);

    // Smoke distortion pulse
    vec2 offset = (warp_r - 0.5) * (env * 0.05);
    vec2 sampled_uv = clamp(uv + offset, 0.0, 1.0);

    vec4 color = texture(tex, sampled_uv);
    // Subtle smoke glow/shading pulse
    float smoke_tint = 1.0 - (fluid * env * 0.12);
    color.rgb *= smoke_tint;

    fragColor = color;
}
