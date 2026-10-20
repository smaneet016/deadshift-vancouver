shader_type sky;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void sky(){
    vec3 d=EYEDIR;
    vec2 p=d.xz/(abs(d.y)+0.28)*2.4;
    float n=noise(p)*0.55+noise(p*2.1)*0.28+noise(p*4.3)*0.12+noise(p*8.4)*0.05;
    float horizon=pow(1.-abs(d.y),3.0);
    vec3 color=mix(vec3(0.008,0.014,0.027),vec3(0.065,0.10,0.14),horizon);
    color+=vec3(0.075,0.095,0.12)*smoothstep(0.24,0.8,n);
    color*=mix(0.2,1.7,n);
    float moon=pow(max(dot(d,normalize(vec3(-0.4,0.5,-0.8))),0.),200.);
    color+=vec3(0.14,0.19,0.25)*moon*(1.-n);
    COLOR=color;
}
