#version 430 compatibility

uniform sampler2D texture;

#include "/lib/fog.glsl"

const int GL_LINEAR = 9729;
const int GL_EXP = 2048;

in vec4 color;
in vec2 coord0;

void main()
{
     vec4 col = color * texture2D(texture, coord0);

    float fog = 0.0;

    // Calculate fog intensity based on mode.
    if (fogMode == GL_LINEAR) {
        fog = clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0, 1.0);
    } else if (fogMode == GL_EXP || isEyeInWater >= 1) {
        fog = 1.0 - clamp(exp(-gl_FogFragCoord * gl_Fog.density), 0.0, 1.0);
    }

    col.rgb = mix(col.rgb, gl_Fog.color.rgb, max(0.02,fog));

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = col;
}
