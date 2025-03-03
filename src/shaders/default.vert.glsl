#version 330 core

layout (location = 0) in vec3 pos;
layout (location = 1) in vec3 color;
layout (location = 2) in vec2 texcoord;

out vec3 vertex_pos;
out vec3 vertex_color;
out vec2 vertex_texcoord;

uniform mat4 mvp;

void main() {
  gl_Position = mvp * vec4(pos, 1.0);
  vertex_pos = gl_Position.xyz;
  vertex_color = color;
  vertex_texcoord = texcoord;
}
