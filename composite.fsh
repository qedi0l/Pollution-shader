#version 430 compatibility

in vec2 texcoord;

uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform sampler2D noisetex;          // Noise texture for cloud shapes
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float far;
uniform float frameTimeCounter;
uniform int worldTime;

layout(location = 0) out vec4 color;

#include "volumetric_fog.glsl"

void main() {
    // Sample the main color buffer
    vec4 sceneColor = texture(gcolor, texcoord);
    
    
    float depth = texture(depthtex0, texcoord).r;

    // Reconstruct view position from depth buffer
    vec4 clipPos = vec4(texcoord * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 viewPos = gbufferProjectionInverse * clipPos;
    viewPos /= viewPos.w; // Perspective divide
    
    // Use dithering for better sample distribution
    float dither = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898, 78.233))) * 43758.5453);
    
    // Distance from camera to the opaque surface at this pixel (view space).
    // For sky pixels (depth == 1.0) this is the far plane, so fog renders fully.
    // Hidden blocks (alpha == 0) are treated as sky so fog renders through them.
    float sceneDist = (sceneColor.a < 0.5) ? far : length(viewPos.xyz);
    
    // Render volumetric fog (density calculated at each sample point)
    vec4 fog = GetVolumetricFog(viewPos.xyz, dither, sceneDist);
    // vec4 fog = vec4(1.);
    
    // Blend fog over scene (fog.a is absorbance, so use 1.0 - fog.a for opacity)
    float blendFactor = (1.0 - fog.a) ;
    vec3 finalColor = mix(sceneColor.rgb, fog.rgb, blendFactor);
    color = vec4(finalColor, sceneColor.a);
}
