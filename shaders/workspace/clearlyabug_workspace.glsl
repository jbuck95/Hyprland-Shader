#version 320 es
// @settle 0.35
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float time;
uniform float seed;
uniform vec2 surface_size;
uniform vec2 resolution;
uniform vec2 velocity;
uniform vec2 peak_velocity;
uniform vec2 move_delta;
uniform float is_moving;
uniform float settle;

precision highp float;



/*
    'Clearly a bug - A Happy Accident' Raymarch Shader
    Inspired by @XorDev, @byt3_m3chanic, @FabriceNeyrat2, @iq, @shane
    Adapted for Hyprland window transition.
*/
vec3 bugEffect(vec2 fragCoord, vec2 res, float animTime) {
    float d = 0.0;
    float z = fract(dot(fragCoord, sin(fragCoord))) - 0.5;
    vec4 o = vec4(0.0);
    vec4 p = vec4(0.0);
    vec4 O = vec4(0.0);

    for (float i = 0.0; i < 50.0; i += 1.0) {
        p = vec4(z * normalize(vec3(fragCoord - 0.5 * res, res.y)), 0.1 * animTime);
        p.z += animTime;
        O = p;

        p.xy *= mat2(cos(2.0 + O.z + vec4(0.0, 11.0, 33.0, 0.0)));
        p.xy *= mat2(cos(O + vec4(0.0, 11.0, 33.0, 0.0)));

        O = (1.0 + sin(0.5 * O.z + length(p - O) + vec4(0.0, 4.0, 3.0, 6.0)))
            / (0.5 + 2.0 * dot(O.xy, O.xy));

        p = abs(fract(p) - 0.5);
        d = abs(min(length(p.xy) - 0.125, min(p.x, p.y) + 1e-3)) + 1e-3;

        o += (O.w / d) * O;
        z += 0.7 * d;
    }

    return tanh(o.rgb / 20000.0);
}


void main() {
    float _ws_spd = length(velocity);
    float _ws_peak_spd = length(peak_velocity);

    float _ws_slide_energy = clamp(_ws_spd / 10000.0, 0.0, 1.0);
    float _ws_tail_energy = clamp(_ws_peak_spd / 10000.0, 0.0, 1.0) * (1.0 - settle) * (1.0 - settle);
    float _ws_energy = (settle > 0.001 || is_moving < 0.5) ? _ws_tail_energy : _ws_slide_energy;

    if (_ws_energy < 0.002) {
        fragColor = texture(tex, v_texcoord);
        return;
    }

    vec2 _ws_dir = _ws_spd > 1.0 ? normalize(velocity) : (length(move_delta) > 1.0 ? normalize(move_delta) : vec2(1.0, 0.0));
    float _ws_progress = 1.0 - _ws_energy * 0.75;


    float p = _ws_progress;
    vec2 uv = v_texcoord;
    float seed_local = seed * 100.0;
    vec2 res = max(surface_size, vec2(1.0));

    float animTime = (p * 2.5 + seed_local);

    vec3 col = clamp(bugEffect(uv * res, res, animTime), 0.0, 4.0);
    float energy = clamp(dot(col, vec3(0.299, 0.587, 0.114)), 0.0, 1.0);

    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));

    float appear = (1.0 - dist * 1.2) + (1.0 - energy) * 0.7;
    float reveal = smoothstep(appear + 0.5, appear - 0.5, (1.0 - p) * 1.8);

    vec2 warp_r = clamp(vec2(dFdx(energy), dFdy(energy)) * 25.0 + 0.5, 0.0, 1.0);
    float distort_strength = (1.0 - p) * (1.0 - p) * 0.35;
    vec2 warped_uv = uv + (warp_r - 0.5) * distort_strength;

    vec4 screen = texture(tex, warped_uv);

    float edge = smoothstep(0.0, 0.6, reveal) * smoothstep(1.0, 0.4, reveal);
    vec3 final_rgb = mix(screen.rgb, col, edge * 0.9);

    float mask = screen.a * reveal;
    fragColor = vec4(final_rgb * mask, mask);

}
