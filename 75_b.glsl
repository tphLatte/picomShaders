#version 330
uniform sampler2D tex;

in vec2 texcoord; 
int pixelsize = 1;

vec4 default_post_processing(vec4 c);

vec4 posterize(vec4 inputColor){
  float gamma = 0.3f;
  float numColors = 64.0f;
  

  vec3 c = inputColor.rgb;
  c = pow(c, vec3(gamma, gamma, gamma));
  c = c * numColors;
  c = floor(c);
  c = c / numColors;
  c = pow(c, vec3(1.0/gamma));
  
  return vec4(c, inputColor.a);
}

vec4 window_shader() {
    vec4 c = texelFetch(tex, ivec2(texcoord), 0);
    c = default_post_processing(c);

    int cx = int(texcoord.x);
    int cy = int(texcoord.y);

    int alpha = ( (cx/pixelsize) % 2) ^ ( (cy/pixelsize) %2);
    c = c * float(alpha); 
    ;
    c = posterize(c);
    return c;
}
