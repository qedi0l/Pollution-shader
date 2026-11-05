#version 430 compatibility

in vec2 texcoord;

uniform sampler2D gcolor;

layout(location = 0) out vec4 color;

void main() {
    // Sample the composite output and write to screen
    color = texture(gcolor, texcoord);
}
