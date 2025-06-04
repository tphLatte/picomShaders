#version 330
uniform sampler2D tex;

in vec2 texcoord; 

vec4 default_post_processing(vec4 c);

vec4 window_shader() {
    vec4 c = texelFetch(tex, ivec2(texcoord), 0);
    c = default_post_processing(c);
    float alpha = 
    max(
    	mod(floor(texcoord.x ), 2.0) 
	,
    	mod(floor(texcoord.y ), 2.0) 
    );
    c = c * alpha;     
    return c;
}
