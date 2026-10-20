shader_type spatial;
uniform vec4 tint : source_color = vec4(0.22, 0.24, 0.26, 1.0);
uniform float brickwork = 0.0;
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
    vec2 p = vec2(world_pos.x + world_pos.z, world_pos.y);
    vec2 cell = vec2(0.7, 0.24) * mix(3.0, 1.0, brickwork);
    p.x += mod(floor(p.y / cell.y), 2.0) * cell.x * 0.5;
    vec2 tile = fract(p / cell);
    vec2 edge = min(tile, 1.0 - tile);
    vec2 aa = fwidth(p / cell) * 1.5;
    float mortar = smoothstep(0.02, 0.02 + aa.x, edge.x) * smoothstep(0.04, 0.04 + aa.y, edge.y);
    float weathering = mix(0.68, 1.1, hash(floor(p / cell)));
    ALBEDO = tint.rgb * weathering * mix(0.45, 1.0, mortar);
    ROUGHNESS = 0.78;
}
