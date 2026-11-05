#version 430 compatibility

// Model-view matrix and its inverse
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

// Pass vertex information to fragment shader
out vec4 color;

void main()
{
    vec3 worldPos = (gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex)).xyz;

    // Calculate clip position using transformed world position
    gl_Position = gl_ProjectionMatrix * gbufferModelView * vec4(worldPos, 1.0);
    gl_FogFragCoord = length(worldPos);

    // Pass vertex color to fragment shader
    color = gl_Color;
}