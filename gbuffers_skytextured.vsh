#version 430 compatibility

//Model * view matrix and it's inverse.
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

//Pass vertex information to fragment shader.
out vec4 color;
out vec2 coord0;

void main()
{
    //Calculate world space position.
    vec3 pos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    pos = (gbufferModelViewInverse * vec4(pos,1)).xyz;

    //Output position and fog to fragment shader.
    gl_Position = gl_ProjectionMatrix * gbufferModelView * vec4(pos,1);

    //Output color to fragment shader.
    color = vec4(gl_Color.rgb, gl_Color.a);
    //Output diffuse texture coordinates to fragment shader.
    coord0 = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	gl_Position.xy = gl_Position.xy;
}
