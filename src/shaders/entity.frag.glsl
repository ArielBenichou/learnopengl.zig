#version 330 core

struct Material {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float shininess;
};

struct Light {
    vec3 position;
  
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

in vec3 frag_pos;
in vec3 normal;

uniform Light light;  
uniform Material material;

uniform vec3 view_pos;

out vec4 frag_color;

void main() {
  vec3 norm = normalize(normal);
  vec3 view_dir = normalize(view_pos - frag_pos);
  vec3 light_dir = normalize(light.position - frag_pos);

   // ambient
  vec3 ambient = light.ambient * material.ambient;

  // diffuse
  float diff = max(dot(norm, light_dir), 0.0);
  vec3 diffuse = light.diffuse * (diff * material.diffuse);

  // specular
  vec3 reflect_dir = reflect(-light_dir, norm);
  float spec = pow(max(dot(view_dir, reflect_dir), 0.0), material.shininess);
  vec3 specular = light.specular * (spec * material.specular);


  vec3 result = ambient + diffuse + specular;
  frag_color = vec4(result, 1);
}

