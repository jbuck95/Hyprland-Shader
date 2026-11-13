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




            // Ported from skwd-wall flyeye transition

            

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

                float sz = 0.04;
                float zoom = 50.0;
                float inv = 1.0 - p;
                vec2 disp = sz * vec2(cos(zoom * uv.x), sin(zoom * uv.y));
                vec2 sample_uv = uv + inv * disp;

                vec2 tc = sample_uv;
                vec4 win = texture(tex, tc.st);

                fragColor = win * p;
            
}
