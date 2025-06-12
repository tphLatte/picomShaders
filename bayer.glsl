#version 430

bool monochrome = false; // Whether to apply a black & white filter to the window

// You can modify the list of patterns to whatever you like, the code will
// adapt to it as long as it is a list of equally sized 2D arrays 
// This example shows a dither pattern list that uses numbers other than
// 0 and 1 for more color variation
// Dither patterns




in vec2 texcoord; 
float colorNum = 4.0;
float colorsPerChannel = 63.0;

uniform sampler2D tex;        // texture of the window
ivec2 iResolution = textureSize(tex, 0);


const int cluster8x8[64] = int[64](
    0, 48, 12, 60,  3, 51, 15, 63,
  32, 16, 44, 28, 35, 19, 47, 31,
    8, 56,  4, 52, 11, 59,  7, 55,
  40, 24, 36, 20, 43, 27, 39, 23,
    2, 50, 14, 62,  1, 49, 13, 61,
  34, 18, 46, 30, 33, 17, 45, 29,
  10, 58,  6, 54,  9, 57,  5, 53,
  42, 26, 38, 22, 41, 25, 37, 21 
);

float getMat2(vec2 uv) {
    int ix = int(uv.x) % 8;
    int iy = int(uv.y) % 8;
    
    return float(cluster8x8[ix + iy*8 ])/1.0;
}

vec4 default_post_processing(vec4 c);
vec3 posterize(vec3);

float posty(float c){
    return floor(c * (colorNum - 1.0) + 0.5) / (colorNum - 1.0);
}

float ditherl(vec2 uv, float luma){
    float m = getMat2(uv); 
    float limit = ( m  + 1.0) / (1.0 + 32.0);
    float luma_p = posty(luma); 
    return luma < limit ? luma_p  : luma_p + (1.0)/(colorNum); 
    return luma_p;
    
}
vec3 dither(vec2 uv, vec3 col) {
    float m = getMat2(uv);
    vec3 luma = vec3(0.299, 0.587, 0.114);
      float grayscale = dot(col, luma);
    return vec3(
         ditherl(uv,col.r),
         ditherl(uv,col.g),
         ditherl(uv,col.b)
    );
}
vec3 posterize(vec3 color){


  color.r = floor(color.r * (colorsPerChannel - 1.0) + 0.5) / (colorsPerChannel - 1.0);
  color.g = floor(color.g * (colorsPerChannel - 1.0) + 0.5) / (colorsPerChannel - 1.0);
  color.b = floor(color.b * (colorsPerChannel - 1.0) + 0.5) / (colorsPerChannel - 1.0);
  return color;

}

vec4 window_shader() {
 
    vec4 c = texelFetch(tex, ivec2(texcoord), 0);
    c = default_post_processing(c);
    c.rgb = dither( texcoord, c.rgb );
    return (c);

}
