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




            // Ported from skwd-wall crazy-parametric transition

            

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

                float a = 4.0;
                float b = 1.0;
                float amplitude = 120.0;
                float smoothness = 0.1;
                vec2 dir = uv - vec2(0.5);
                float dist = length(dir);
                float xx = (a - b) * cos(p) + b * cos(p * ((a / b) - 1.0));
                float yy = (a - b) * sin(p) - b * sin(p * ((a / b) - 1.0));
                vec2 offset = dir * vec2(sin(p * dist * amplitude * xx), sin(p * dist * amplitude * yy)) / smoothness;

                vec2 tc = uv;
                vec4 win = texture(tex, tc.st);

                float reveal = smoothstep(0.2, 1.0, p);
                fragColor = win * reveal;
            
}
