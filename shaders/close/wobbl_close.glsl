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

// "Wobbl" doesn't generate its own color field, unlike the other reference
// shaders — it only distorts the window's own texture. So instead of the
// energy/dissolve-mask scheme used elsewhere, this ramps the original
// wobble + a slight inward zoom together with progress, then fades to black.
void main() {
    float p = progress;
    vec2 uv = v_texcoord;
    float seed_local = seed * 100.0;

    float t = p * 6.0 + seed_local;

    // ease from the untouched image towards the original 0.8*uv+0.1 zoom
    vec2 zoomed_uv = mix(uv, uv * 0.8 + 0.1, p);

    float wobble_amt = 0.025 * smoothstep(0.0, 1.0, p);
    vec2 wobbled_uv = zoomed_uv + cos(t * vec2(4.0, 6.0) + zoomed_uv * 10.0) * wobble_amt;

    vec4 color = texture(tex, wobbled_uv);

    float tail = smoothstep(1.0, 0.85, p);
    fragColor = color * (1.0 - p) * tail;
}
