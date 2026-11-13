#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;

// See wobbl_close.glsl for why this uses a simpler scheme than the other
// converted shaders: "Wobbl" has no independent color field of its own.
void main() {
    float p = progress;
    vec2 uv = v_texcoord;
    float seed_local = seed * 100.0;

    float t = p * 6.0 + seed_local;

    // ease from the original 0.8*uv+0.1 zoom towards the untouched image
    vec2 zoomed_uv = mix(uv * 0.8 + 0.1, uv, p);

    float wobble_amt = 0.025 * smoothstep(0.0, 1.0, 1.0 - p);
    vec2 wobbled_uv = zoomed_uv + cos(t * vec2(4.0, 6.0) + zoomed_uv * 10.0) * wobble_amt;

    vec4 color = texture(tex, wobbled_uv);

    fragColor = color * p;
}
