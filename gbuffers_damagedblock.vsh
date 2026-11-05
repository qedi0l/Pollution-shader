#version 430 compatibility

out vec2 coord0;
out vec2 coord1;

attribute float mc_Entity;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform int frameCounter;
uniform float viewWidth, viewHeight;

void main() {
    // Calculate world space position.
    vec3 pos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    pos = (gbufferModelViewInverse * vec4(pos, 1.0)).xyz;

    // Output position and fog to fragment shader.
    gl_Position = gl_ProjectionMatrix * gbufferModelView * vec4(pos, 1.0);
    gl_FogFragCoord = length(pos);

    // Output diffuse and lightmap texture coordinates to fragment shader.
    coord0 = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    coord1 = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

	gl_Position.xy = gl_Position.xy;
}