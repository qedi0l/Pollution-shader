#version 430 compatibility

// Input from vertex shader
in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 normal;
in vec3 vPosPlayer;
in vec3 vPosView;
in float mcentity;

// Output
layout(location = 0) out vec4 color;

// Uniforms
uniform sampler2D noisetex;
uniform sampler2D lightmap;
uniform sampler2D texture;
uniform vec3 eyePosition;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;

void main() {
    if (mcentity == 2) {
        discard;
    }
    // Sample the original texture
    vec4 texColor = texture(texture, texcoord);
    
    color = texColor * glcolor;
    color.a = texColor.a;
}
