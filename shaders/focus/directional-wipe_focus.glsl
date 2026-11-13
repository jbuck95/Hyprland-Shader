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




            // Ported from skwd-wall directional-wipe transition

            

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
                vec2 tc = uv;
                vec4 win = texture(tex, tc.st);

                vec2 dir = vec2(1.0, -1.0);
                float smoothness = 0.5;
                vec2 center = vec2(0.5, 0.5);
                vec2 v = normalize(dir);
                v /= abs(v.x) + abs(v.y);
                float d = v.x * center.x + v.y * center.y;
                float reveal = (1.0 - step(p, 0.0)) *
                    (1.0 - smoothstep(-smoothness, 0.0, v.x * uv.x + v.y * uv.y - (d - 0.5 + p * (1.0 + smoothness))));

                fragColor = win * reveal;
            
}
