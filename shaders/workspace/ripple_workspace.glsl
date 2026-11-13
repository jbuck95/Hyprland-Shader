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



            // Ported from gl-transitions/ripple.glsl (MIT, gre)

            

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
                float seed_local = seed * 6.28318;

                float amplitude = 100.0;
                float speed = 50.0;

                vec2 dir = uv - vec2(0.5);
                float dist = length(dir);

                float intensity = (1.0 - p) * (1.0 - p);
                vec2 offset = dir * (sin(p * dist * amplitude - p * speed + seed_local) + 0.5) / 30.0;

                vec2 wuv = uv + offset * intensity;
                vec2 tc = wuv;
                vec4 color = texture(tex, tc.st);

                float alpha = smoothstep(0.0, 0.3, p);
                fragColor = color * alpha;
            
}
