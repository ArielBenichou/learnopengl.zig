#version 330 core

in vec3 vertex_color;
in vec3 vertex_pos;
in vec2 vertex_texcoord;

uniform sampler2D base_tex;
uniform sampler2D overlay_tex;

out vec4 frag_color;

void main() {
  frag_color = mix(
    texture(base_tex, vertex_texcoord),
    texture(overlay_tex, vertex_texcoord),
    0.2 
  ) * vertex_pos.xxxx;
}
