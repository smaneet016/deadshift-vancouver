shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
    vec2 p=UV;
    float wobble=sin(p.y*13.-TIME*8.)*0.08+sin(p.y*21.+TIME*5.)*0.035;
    float width=(1.-p.y)*0.0+p.y*0.38;
    float shape=smoothstep(width+0.04,width,abs(p.x-0.5+wobble));
    float flicker=0.75+0.25*sin(TIME*13.+p.y*12.);
    ALBEDO=vec3(1.,0.3,0.02);
    EMISSION=mix(vec3(2.,0.08,0.01),vec3(5.,2.1,0.35),p.y)*flicker;
    ALPHA=shape*smoothstep(0.,0.18,p.y)*0.85;
}
