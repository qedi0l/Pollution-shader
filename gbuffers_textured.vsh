#version 430 compatibility

// Get Entity id
attribute float mc_Entity;

// Model * view matrix and its inverse
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

// Pass vertex information to fragment shader
out vec4 fragColor;
out vec2 texCoord0;
out vec2 texCoord1;

#include "/lib/diffuse.glsl"

void main() {
    // Calculate world space position
    vec3 worldPos = (gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex).xyz;

    // Output position and fog to fragment shader
    gl_Position = gl_ProjectionMatrix * gbufferModelView * vec4(worldPos, 1.0);
    gl_FogFragCoord = length(worldPos);

    // Calculate view space normal
    vec3 normal = normalize(gl_NormalMatrix * gl_Normal);
    normal = (mc_Entity == 1.0) ? vec3(0.0, 1.0, 0.0) : (gbufferModelViewInverse * vec4(normal, 0.0)).xyz;

    // Calculate simple lighting
    float lightIntensity = VanillaDiffuse(normal);

    // Output color with lighting to fragment shader
    fragColor = vec4(gl_Color.rgb * lightIntensity, gl_Color.a);

    // Output texture coordinates to fragment shader
    texCoord0 = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    texCoord1 = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	
	gl_Position.xy = gl_Position.xy;
}
