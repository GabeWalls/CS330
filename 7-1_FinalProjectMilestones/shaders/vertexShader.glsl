#version 330 core
layout (location = 0) in vec3 inVertexPosition;
layout (location = 1) in vec3 inVertexNormal;
layout (location = 2) in vec2 inTextureCoordinate;

out vec3 fragmentPosition;
out vec3 fragmentVertexNormal;
out vec2 TexCoords; // renamed for fragment shader compatibility

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform vec2 UVscale; // optional but recommended

void main()
{
    fragmentPosition = vec3(model * vec4(inVertexPosition, 1.0));
    gl_Position = projection * view * model * vec4(inVertexPosition, 1.0);
    fragmentVertexNormal = inVertexNormal;
    TexCoords = inTextureCoordinate * UVscale; // proper scaling + naming
}
