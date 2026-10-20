shader_type spatial;
uniform sampler2D asphalt_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D asphalt_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D asphalt_roughness : filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 base_color : source_color = vec4(0.16, 0.18, 0.19, 1.0);
uniform float water = 0.0;
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) { vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y); }
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
    vec2 uv=world_pos.xz*0.22;
    float puddle=clamp(smoothstep(0.28,0.57,noise(world_pos.xz*0.29)),0.0,1.0);
    puddle=mix(puddle,1.0,water);
    vec3 road=texture(asphalt_color,uv).rgb;
    ALBEDO=mix(road*base_color.rgb,base_color.rgb*0.18,water)*mix(1.0,0.55,puddle);
    ROUGHNESS=mix(texture(asphalt_roughness,uv).r*0.65,0.045,puddle);
    METALLIC=0.2;
    SPECULAR=0.95;
    vec3 n=texture(asphalt_normal,uv).rgb;
    n.xy=mix(n.xy,vec2(0.5),puddle*0.96);
    vec2 r=vec2(sin(world_pos.x*33.0+TIME*2.2),cos(world_pos.z*37.0+TIME*1.7))*0.012;
    n.xy+=r*puddle;
    NORMAL_MAP=n;
    NORMAL_MAP_DEPTH=0.75;
}
