#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;


            // Ported from skwd-wall soft-warp-fade transition

            float swf_hash(vec2 p) {
                return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
            }

            float swf_noise(vec2 p) {
                vec2 i = floor(p);
                vec2 f = fract(p);
                f = f * f * (3.0 - 2.0 * f);
                return mix(mix(swf_hash(i), swf_hash(i + vec2(1.0, 0.0)), f.x),
                           mix(swf_hash(i + vec2(0.0, 1.0)), swf_hash(i + vec2(1.0, 1.0)), f.x), f.y);
            }

            
void main() {

                float p = progress;
                vec2 uv = v_texcoord;

                float strength = sin(p * 3.14159) * 0.025;
                vec2 warp = vec2(
                    swf_noise(uv * 3.0 + vec2(0.0, p * 0.5)),
                    swf_noise(uv * 3.0 + vec2(p * 0.5, 0.0))
                ) - 0.5;
                vec2 warped = uv + warp * strength;

                vec2 tc = warped;
                vec4 win = texture(tex, tc.st);

                float t = smoothstep(0.05, 0.95, p);
                t = t * t * (3.0 - 2.0 * t);
                fragColor = win * t;
            }

