shader_type spatial;
uniform vec4 glow_color : source_color = vec4(1.0,0.68,0.34,1.0);
uniform float energy = 2.0;
void fragment(){
    vec2 uv=UV;
    float frame=step(0.035,uv.x)*step(uv.x,0.965)*step(0.035,uv.y)*step(uv.y,0.965);
    float blinds=mix(0.4,1.0,smoothstep(0.06,0.18,fract(uv.y*13.0)));
    float edge=sin(uv.x*3.14159)*0.6+0.4;
    ALBEDO=vec3(0.025,0.035,0.04);
    EMISSION=glow_color.rgb*energy*frame*blinds*edge;
    ROUGHNESS=0.22;METALLIC=0.35;
}
