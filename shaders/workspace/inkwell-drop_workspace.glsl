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




            // Ported from skwd-wall inkwell-drop transition

            

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

                vec2 impact = vec2(0.35, 0.4);
                vec2 c = uv - impact;
                c.x *= surface_size.x / max(surface_size.y, 0.0001);
                float d = length(c);
                float front = p * 1.5;
                float ring1 = sin((d - front) * 80.0) * exp(-abs(d - front) * 6.0);
                float ring2 = sin((d - front + 0.08) * 80.0) * exp(-abs(d - front + 0.08) * 8.0) * 0.6;
                float ring3 = sin((d - front + 0.16) * 80.0) * exp(-abs(d - front + 0.16) * 10.0) * 0.4;
                float ripple = (ring1 + ring2 + ring3) * 0.05 * (1.0 - p * 0.5);
                vec2 dir = (d > 0.001) ? normalize(c) : vec2(0.0);
                vec2 distorted = clamp(uv + dir * ripple, vec2(0.0), vec2(1.0));

                vec2 tc = distorted;
                vec4 win = texture(tex, tc.st);

                float reveal = smoothstep(0.05, -0.02, d - front);
                vec4 mixed = win * reveal;

                float in_bounds = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
                fragColor = mixed * in_bounds;
            
}
