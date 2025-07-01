#version 430

bool monochrome = false; // Whether to apply a black & white filter to the window

// You can modify the list of patterns to whatever you like, the code will
// adapt to it as long as it is a list of equally sized 2D arrays 
// This example shows a dither pattern list that uses numbers other than
// 0 and 1 for more color variation
// Dither patterns




in vec2 texcoord; 
float colorNum = 8.0;
float colorsPerChannel = 63.0;

uniform sampler2D tex;        // texture of the window
ivec2 iResolution = textureSize(tex, 0);

void make_kernel(inout vec4 n[9] , vec2 coord)
{
	float w = 1.0; 
	float h = 1.0;

	n[0] = texelFetch(tex, ivec2(coord) + ivec2( -w, -h), 0);
	n[1] = texelFetch(tex, ivec2(coord)+ ivec2(0.0, -h), 0);
	n[2] = texelFetch(tex, ivec2(coord)+ ivec2(  w, -h), 0);
	n[3] = texelFetch(tex, ivec2(coord)+ ivec2( -w, 0.0), 0);
	n[4] = texelFetch(tex, ivec2(coord), 0);
	n[5] = texelFetch(tex, ivec2(coord)+ ivec2(  w, 0.0), 0);
	n[6] = texelFetch(tex, ivec2(coord)+ ivec2( -w, h), 0);
	n[7] = texelFetch(tex, ivec2(coord)+ ivec2(0.0, h), 0);
	n[8] = texelFetch(tex, ivec2(coord)+ ivec2(  w, h), 0);

}

vec3 linear_from_srgb(vec3 rgb) {
    return pow(rgb, vec3(2.2));
}
//Convert linear RGB to sRGB
vec3 srgb_from_linear(vec3 lin)
{
    return pow(lin, vec3(1.0/2.2));
}

//By Björn Ottosson
//https://bottosson.github.io/posts/oklab
//Shader functions adapted by "mattz"
//https://www.shadertoy.com/view/WtccD7

vec3 oklab_from_linear(vec3 linear) {
    const mat3 im1 = mat3(0.4121656120, 0.2118591070, 0.0883097947,
                          0.5362752080, 0.6807189584, 0.2818474174,
                          0.0514575653, 0.1074065790, 0.6302613616);
                       
    const mat3 im2 = mat3(+0.2104542553, +1.9779984951, +0.0259040371,
                          +0.7936177850, -2.4285922050, +0.7827717662,
                          -0.0040720468, +0.4505937099, -0.8086757660);
                       
    vec3 lms = im1 * linear;
            
    return im2 * (sign(lms) * pow(abs(lms), vec3(1.0/3.0)));
}

vec3 linear_from_oklab(vec3 oklab) {
    const mat3 m1 = mat3(+1.000000000, +1.000000000, +1.000000000,
                         +0.396337777, -0.105561346, -0.089484178,
                         +0.215803757, -0.063854173, -1.291485548);
                       
    const mat3 m2 = mat3(+4.076724529, -1.268143773, -0.004111989,
                         -3.307216883, +2.609332323, -0.703476310,
                         +0.230759054, -0.341134429, +1.706862569);
    vec3 lms = m1 * oklab;
    
    return m2 * (lms * lms * lms);
}

vec3 oklab_from_srgb(vec3 rgb){
  return oklab_from_linear(linear_from_srgb(rgb));
}

vec3 srgb_from_oklab(vec3 oklab){
  return srgb_from_linear(linear_from_oklab(oklab));
}



vec4 sobel_f(vec2 coord){

	vec4 n[9];
	make_kernel( n,coord);

	vec4 sobel_edge_h = n[2] + (2.0*n[5]) + n[8] - (n[0] + (2.0*n[3]) + n[6]);
  vec4 sobel_edge_v = n[0] + (2.0*n[1]) + n[2] - (n[6] + (2.0*n[7]) + n[8]);
	vec4 sobel = sqrt((sobel_edge_h * sobel_edge_h) + (sobel_edge_v * sobel_edge_v));
//if (sobel == vec4(0.0)) return vec4(1.0);

  return sobel;

}


const int cluster8x8[64] = int[64](

    24,8,22,30,34,44,42,32,
    10,0,6,20,46,58,56,40,
    12,2,4,18,48,60,62,54,
    26,14,16,28,36,50,52,38,
    35,45,43,33,25,9,23,31,
    47,59,57,41,11,1,7,21,
    49,61,63,55,13,3,5,19,
    37,51,53,39,27,15,17,29


);

float getMat2(vec2 uv) {
    int ix = int(uv.x) % 8;
    int iy = int(uv.y) % 8;
    
    return float(cluster8x8[ix + iy*8 ])/1.0;
}

vec4 default_post_processing(vec4 c);
vec3 posterize(vec3);


float posty_p(float n, float c){
    return floor(c * (n- 1.0) + 0.5) / (n - 1.0);
}

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


float ditherl_c( float count, vec2 uv, float luma){
    float m = getMat2(uv); 
    float limit = ( m  + 1.0) / (1.0 + 32.0);
    float luma_p = posty(luma); 
    return luma < limit ? luma_p  : luma_p + (1.0)/(count); 
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

vec3 dither_3p(vec3 c_num, vec2 uv, vec3 col){
    return vec3(
         ditherl_c(c_num.r,uv,col.r),
         ditherl_c(c_num.g,uv,col.g),
         ditherl_c(c_num.b,uv,col.b)
    );

}


vec3 posterize_3p(vec3 c_num, vec3 col){
    return vec3(
         posty_p(c_num.r,col.r),
         posty_p(c_num.g,col.g),
         posty_p(c_num.b,col.b)
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
    c.rgb = dither_3p( vec3(2.0,2.0,32.0), texcoord, c.rgb );
    vec4 d = sobel_f(texcoord);
    d.rgb = linear_from_oklab(dither_3p(vec3(16.0,8.0,8.0),  texcoord, oklab_from_linear(d.rgb)));
    d.a=0.0;
    c = (c)*1 - d*0.1;
    c.a = 1.0;
    return c;

}
