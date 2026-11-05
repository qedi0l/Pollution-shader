#version 430 compatibility

// Input attributes from Minecraft
in vec3 Position;
in vec2 UV0;
in vec2 UV1;
in vec4 Color;
in vec2 mc_Entity;
in vec4 at_midBlock;

// Output to fragment shader
out vec2 texcoord;
out vec2 lmcoord;
out vec4 glcolor;
out vec3 normal;
out vec3 vPosPlayer;
out vec3 vPosView;
out float mcentity;

// Uniforms
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

// Note: glass block positions are written to the SSBO by the mod
// (GlassSsboWriter) every frame, not by this vertex shader.

void main() {
    // Transform position
    gl_Position = ftransform();
    
    // Pass texture coordinates
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    
    // Pass color (biome tint)
    glcolor = gl_Color;
    
    // Calculate normal in world/player space
    normal = gl_NormalMatrix * gl_Normal;
    normal = mat3(gbufferModelViewInverse) * normal;
    
    // gl_Vertex is in view space (player-relative) in Minecraft
    // at_midBlock gives the offset from vertex to block center in 1/64th units
    // Block center in world space = vertex world pos + offset
    vec3 vertexWorldPos = gl_Vertex.xyz + cameraPosition;
    vec3 blockCenter = vertexWorldPos + at_midBlock.xyz / 64.0;
    vPosPlayer = blockCenter;
    
    // Calculate vertex position in view space
    vPosView = gl_Vertex.xyz;
    
    // Pass entity/block ID data (used to identify glass)
    mcentity = mc_Entity.x;
}
