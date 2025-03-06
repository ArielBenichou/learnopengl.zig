#version 330 core

layout (location = 0) in vec3 pos;
layout (location = 1) in vec2 texcoord;

out vec3 vertex_pos;
out vec2 vertex_texcoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main() {
  gl_Position = projection * view * model * vec4(pos, 1.0);
  vertex_pos = gl_Position.xyz;
  vertex_texcoord = texcoord;
}
