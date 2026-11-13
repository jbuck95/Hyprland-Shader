#version 320 es
// @duration 0.5
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;
uniform vec2 resolution;

            // Ported from gl-transitions/ripple.glsl (MIT, gre)

            
void main() {

                float p = 1.0 - progress;
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

