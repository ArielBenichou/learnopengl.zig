#version 330 core

in vec3 frag_pos;
in vec3 normal;

uniform vec3 object_color;
uniform vec3 light_color;
uniform vec3 light_pos;

out vec4 frag_color;

void main() {
  // diffuse
  vec3 norm = normalize(normal);
  vec3 light_dir = light_pos - frag_pos;
  vec3 light_dir_norm = normalize(light_dir);
  float distance_strength = 2 / length(light_dir);
  float diff = max(dot(norm, light_dir_norm), 0.0);
  // remove distance_strength for flast "sun" light, else thi is "spot" lighting
  vec3 diffuse = diff * light_color * distance_strength;

  // ambient
  float ambient_strength = 0.1;
  vec3 ambient = ambient_strength * light_color;

  vec3 result = (ambient + diffuse) * object_color;
  frag_color = vec4(result, 1);
}
