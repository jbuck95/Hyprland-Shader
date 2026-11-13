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



/*
    'Synapse (parametric)' by anAccount (Created: 2026-09-04)
    Adapted for Hyprland window transitions.
*/
#define U_SCALE  0.6
#define U_THICK  0.0
#define U_SPEED  0.46
#define U_WARP   2.50
#define U_DEPTH  25.40

#define U_COL_A  vec3(0.0, 0.25, 1.00)
#define U_COL_B  vec3(0.30, 0.30, 1.00)
#define U_GLOW   4.6

mat2 rot(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

float gyroid(vec3 p) {
    p *= U_SCALE;
    return abs(dot(sin(p), cos(p.yzx))) / U_SCALE - U_THICK;
}

float map(vec3 p, float time) {
    return gyroid(p + U_WARP * sin(p.yzx * 1.7 + time * 0.6));
}

vec3 synapseEffect(vec2 p_uv, float animTime) {
    float tt = animTime * U_SPEED;
    vec3 ro = vec3(0.8 * sin(tt * 0.4), 0.8 * cos(tt * 0.3), tt);
    vec3 rd = normalize(vec3(p_uv, 1.6));
    rd.yz = rot(0.5 * sin(tt * 0.30)) * rd.yz;
    rd.xz = rot(0.6 * cos(tt * 0.23)) * rd.xz;

    float t = 0.0;
    float atten = 1.0;
    vec3 col = vec3(0.0);

    for (int i = 0; i < 60; i++) {
        vec3 p = ro + rd * t;
        float d = map(p, animTime);
        float ad = abs(d);

        vec3 surfaceColor = mix(U_COL_A, U_COL_B, clamp(ad * 8.0, 0.0, 1.0));
        col += surfaceColor * (U_GLOW * 0.014) * exp(-ad * 8.0) * atten;

        t += max(ad * 0.455, 0.008);
        atten *= 0.999;
        if (t > U_DEPTH) break;
    }

    col += U_COL_A * 0.015;
    col = 1.0 - exp(-col);
    return col;
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
    float seed_local = seed * 10.0;
    vec2 res = max(surface_size, vec2(1.0));

    float animTime = (p * 2.5 + seed_local);

    vec2 p_uv = (uv - 0.5) * 2.0;
    p_uv.x *= res.x / res.y;

    vec3 col = clamp(synapseEffect(p_uv, animTime), 0.0, 4.0);
    float energy = clamp(dot(col, vec3(0.299, 0.587, 0.114)), 0.0, 1.0);

    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));

    float appear = (1.0 - dist * 1.1) + energy * 0.7;
    float reveal = smoothstep(appear + 0.4, appear - 0.4, (1.0 - p) * 1.8);

    vec2 warp_r = clamp(vec2(dFdx(energy), dFdy(energy)) * 25.0 + 0.5, 0.0, 1.0);
    float distort_strength = (1.0 - p) * (1.0 - p) * 0.35;
    vec2 warped_uv = uv + (warp_r - 0.5) * distort_strength;

    vec4 screen = texture(tex, warped_uv);

    float edge = smoothstep(0.0, 0.6, reveal) * smoothstep(1.0, 0.3, reveal);
    vec3 final_rgb = mix(screen.rgb, col + screen.rgb * 0.3, edge * 0.85);

    float mask = screen.a * reveal;
    fragColor = vec4(final_rgb * mask, mask);

}
