#version 330 core

in vec3 vertex_pos;
in vec3 vertex_color;
in vec2 vertex_texcoord;

uniform sampler2D base_tex;
uniform sampler2D overlay_tex;

out vec4 frag_color;

void main() {
  frag_color = mix(
    texture(base_tex, vertex_texcoord),
    texture(overlay_tex, vertex_texcoord),
    0.2 
  );
  frag_color = mix(frag_color, vec4(vertex_color, 1.0), abs(vertex_pos.x/2) + abs(vertex_pos.y/2));
}
