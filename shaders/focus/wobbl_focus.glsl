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



// See wobbl_close.glsl for why this uses a simpler scheme than the other
// converted shaders: "Wobbl" has no independent color field of its own.

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

    // ease from the original 0.8*uv+0.1 zoom towards the untouched image
    vec2 zoomed_uv = mix(uv * 0.8 + 0.1, uv, p);

    float wobble_amt = 0.025 * smoothstep(0.0, 1.0, 1.0 - p);
    vec2 wobbled_uv = zoomed_uv + cos(t * vec2(4.0, 6.0) + zoomed_uv * 10.0) * wobble_amt;

    vec4 color = texture(tex, wobbled_uv);

    fragColor = color * p;

}
