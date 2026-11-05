#version 430 compatibility

uniform sampler2D texture;
uniform sampler2D lightmap;

// Fog mode
#include "/lib/fog.glsl"

const int GL_LINEAR = 9729;
const int GL_EXP = 2048;

// Diffuse and lightmap texture coordinates.
in vec2 coord0;
in vec2 coord1;

void main()
{
    // Sample texture
    vec4 col = texture2D(texture, coord0);

    // Calculate and apply fog intensity.
    if(fogMode == GL_LINEAR){
        float fog = clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0., 1.);
        col.rgb = mix(col.rgb, gl_Fog.color.rgb, max(0.02,fog));
    } else if(fogMode == GL_EXP || isEyeInWater >= 1){
        float fog = 1. - clamp(exp(-gl_FogFragCoord * gl_Fog.density), 0., 1.);
        col.rgb = mix(col.rgb, gl_Fog.color.rgb, max(0.02,fog));
    }

    // Output the result.
    /*DRAWBUFFERS:0*/
    gl_FragData[0] = col;
}
