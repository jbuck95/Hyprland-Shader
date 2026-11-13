#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;


            // Ported from skwd-wall plasma-flow transition

            float pf_hash(vec2 p) {
                return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
            }

            float pf_noise(vec2 p) {
                vec2 i = floor(p);
                vec2 f = fract(p);
                f = f * f * (3.0 - 2.0 * f);
                return mix(mix(pf_hash(i), pf_hash(i + vec2(1.0, 0.0)), f.x),
                           mix(pf_hash(i + vec2(0.0, 1.0)), pf_hash(i + vec2(1.0, 1.0)), f.x), f.y);
            }

            
void main() {

                float p = progress;
                vec2 uv = v_texcoord;

                vec2 flow = vec2(
                    pf_noise(uv * 5.0 + vec2(p * 2.0, 0.0)),
                    pf_noise(uv * 5.0 + vec2(0.0, p * 2.0))
                ) - 0.5;
                float intensity = sin(p * 3.14159) * 0.18;
                vec2 distorted = uv + flow * intensity;

                vec2 tc = distorted;
                vec4 win = texture(tex, tc.st);

                float reveal = smoothstep(0.2, 0.8, p);
                fragColor = win * reveal;
            }

