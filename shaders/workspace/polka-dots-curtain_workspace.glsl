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




            // Ported from skwd-wall polka-dots-curtain transition

            

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
                vec2 tc = uv;
                vec4 win = texture(tex, tc.st);

                float dots = 20.0;
                vec2 center = vec2(0.0, 0.0);
                float reveal = step(distance(fract(uv * dots), vec2(0.5, 0.5)), p / max(distance(uv, center), 0.0001));

                fragColor = win * reveal;
            
}
