#version 330 core

in vec3 vertex_color;
in vec2 vertex_texcoord;

uniform sampler2D tex;

out vec4 frag_color;

void main() {
  frag_color = texture(tex, vertex_texcoord); //vec4(vertex_color, 1.0); 
}
