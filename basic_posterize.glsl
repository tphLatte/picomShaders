#version 330
uniform sampler2D tex;

in vec2 texcoord; 
float colorsPerChannel = 8.0;

vec4 default_post_processing(vec4 c);

vec3 posterize(vec3 color){

  color.r = floor(color.r * (colorsPerChannel - 1.0) + 0.5) / (colorsPerChannel - 1.0);
  color.g = floor(color.g * (colorsPerChannel - 1.0) + 0.5) / (colorsPerChannel - 1.0);
  color.b = floor(color.b * (colorsPerChannel - 1.0) + 0.5) / (colorsPerChannel - 1.0);
  return color;

}

vec4 window_shader() {
    vec4 c = texelFetch(tex, ivec2(texcoord), 0);
    c = default_post_processing(c);
    c.rgb = posterize(c.rgb);
    return (c);
}
