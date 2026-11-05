#version 430 compatibility

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform vec4 entityColor;

const int GL_LINEAR = 9729;
const int GL_EXP = 2048;

#include "/lib/fog.glsl"

in vec4 fragColor;
in vec2 texCoord0;
in vec2 texCoord1;

void main() {
    vec4 color = fragColor * texture2D(lightmap, texCoord1) * texture2D(texture, texCoord0);

    color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);

    float fogFactor;
    if (fogMode == GL_LINEAR) {
        fogFactor = clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0, 1.0);
    } else if (fogMode == GL_EXP || isEyeInWater >= 1) {
        fogFactor = 1.0 - clamp(exp(-gl_FogFragCoord * gl_Fog.density), 0.0, 1.0);
    }
    color.rgb = mix(color.rgb, gl_Fog.color.rgb, max(0.02,fogFactor));

    gl_FragData[0] = color;
}
