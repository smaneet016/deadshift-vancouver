shader_type spatial;
render_mode unshaded,blend_add,cull_disabled,depth_draw_never;
void fragment(){
    vec2 p=UV*2.0-1.0;
    float r=length(p);
    float angle=atan(p.y,p.x);
    float rays=0.30+0.24*pow(abs(sin(angle*3.0)),8.0);
    float shape=1.0-smoothstep(rays*0.35,rays,r);
    vec3 color=mix(vec3(1.0,0.22,0.015),vec3(1.0,0.9,0.55),1.0-smoothstep(0.0,0.24,r));
    ALBEDO=color;
    EMISSION=color*5.0;
    ALPHA=shape;
}
