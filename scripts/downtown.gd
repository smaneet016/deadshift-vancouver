extends Node3D
## Fixed, fictional False Creek block. Collision and routing share obstacle bounds.
const WET = preload("res://shaders/wet_surface.gdshader")
var obstacles: Array[Rect2] = []
var building_specs: Array[Dictionary] = []
var grid := AStarGrid2D.new()
var spawn_points: Array[Vector3] = [Vector3(-11, 0.1, -26), Vector3(11, 0.1, -26), Vector3(-12, 0.1, 25), Vector3(12, 0.1, 25), Vector3(-17, 0.1, 0), Vector3(17, 0.1, 0)]
var batches: Dictionary = {}
var rain: CPUParticles3D
var moon: DirectionalLight3D
var world: WorldEnvironment
var balanced := true
var seeded := RandomNumberGenerator.new()
var concrete: StandardMaterial3D
var metal: StandardMaterial3D
var amber: StandardMaterial3D
var cyan: StandardMaterial3D
var glass: StandardMaterial3D

func _ready() -> void:
    seeded.seed = 197604
    concrete = pbr("concrete_wall_006", 0.35)
    metal = material(Color("202f3a"), 0.65, 0.4)
    amber = emissive(Color("ffad59"), 2.2)
    cyan = emissive(Color("67bacf"), 1.5)
    glass = material(Color("183340"), 0.5, 0.22)
    _environment()
    _streets()
    _buildings()
    _props()
    _waterfront()
    var detail = preload("res://scripts/city_detail.gd").new()
    add_child(detail)
    detail.build(self)
    _batch_meshes()
    _navigation()
    _weather()
    set_quality(true)

func material(color: Color, metallic := 0.0, roughness := 0.85) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = metallic
    mat.roughness = roughness
    return mat

func emissive(color: Color, energy: float) -> StandardMaterial3D:
    var mat := material(color)
    mat.emission_enabled = true
    mat.emission = color
    mat.emission_energy_multiplier = energy
    return mat

func box(pos: Vector3, size: Vector3, mat: Material, solid := false, route := true) -> void:
    # All repeated boxes of one material share one draw batch, no per-window nodes.
    if mat != null:
        if not batches.has(mat): batches[mat] = []
        batches[mat].append(Transform3D(Basis.IDENTITY.scaled(size), pos))
    if solid:
        var body := StaticBody3D.new()
        body.position = pos
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        body.add_child(collision)
        add_child(body)
        if route:
            obstacles.append(Rect2(Vector2(pos.x - size.x / 2, pos.z - size.z / 2), Vector2(size.x, size.z)).grow(0.65))

func _batch_meshes() -> void:
    for mat in batches:
        var instance := MultiMeshInstance3D.new()
        var mm := MultiMesh.new()
        mm.transform_format = MultiMesh.TRANSFORM_3D
        var mesh := BoxMesh.new()
        mesh.size = Vector3.ONE
        mesh.material = mat
        mm.mesh = mesh
        mm.instance_count = batches[mat].size()
        for i in range(mm.instance_count): mm.set_instance_transform(i, batches[mat][i])
        instance.multimesh = mm
        if mat is StandardMaterial3D and mat.emission_enabled:
            instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(instance)
    batches.clear()

func label(words: String, pos: Vector3, size := 48, color := Color.WHITE, yaw := 0.0) -> void:
    var text := Label3D.new()
    text.text = words
    text.position = pos
    text.font_size = size
    text.pixel_size = 0.009
    text.modulate = color
    text.outline_size = 3
    text.rotation.y = yaw
    text.no_depth_test = false
    add_child(text)

func _environment() -> void:
    world = WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_mat := ShaderMaterial.new()
    sky_mat.shader = preload("res://shaders/storm_sky.gdshader")
    sky.sky_material = sky_mat
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("8bacc5")
    env.ambient_light_energy = 0.18
    env.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.glow_enabled = true
    env.glow_intensity = 0.65
    env.glow_bloom = 0.08
    env.glow_hdr_threshold = 1.2
    env.ssr_enabled = true
    env.ssr_max_steps = 64
    env.ssao_enabled = true
    env.ssao_radius = 1.3
    env.ssao_intensity = 1.5
    env.volumetric_fog_enabled = true
    env.volumetric_fog_density = 0.008
    env.volumetric_fog_albedo = Color("8295a4")
    env.volumetric_fog_length = 85.0
    env.fog_enabled = true
    env.fog_light_color = Color("263e50")
    env.fog_light_energy = 0.65
    env.fog_density = 0.0018
    world.environment = env
    add_child(world)
    moon = DirectionalLight3D.new()
    moon.rotation_degrees = Vector3(-48, -32, 0)
    moon.light_color = Color("9dbbd9")
    moon.light_energy = 0.22
    moon.directional_shadow_max_distance = 65.0
    add_child(moon)

func _streets() -> void:
    var road := ShaderMaterial.new()
    road.shader = WET
    wet_textures(road)
    box(Vector3(0, -0.5, 0), Vector3(64, 1, 64), road, true, false)
    # Sidewalks are flush enough for capsule movement without a step controller.
    for x in [-16.0, 16.0]:
        box(Vector3(x, -0.15, 0), Vector3(8, 0.3, 62), concrete, true, false)
        for z in range(-30, 31, 3):
            box(Vector3(x, 0.008, z), Vector3(7.8, 0.014, 0.035), metal)
        box(Vector3(signf(x) * 12.0, 0.035, 0), Vector3(0.15, 0.07, 62), concrete)
    # Continuous physical perimeter; scenery outside never costs navigation work.
    box(Vector3(0, 2.5, 32), Vector3(64, 5, 0.8), concrete, true)
    for x in [-32.0, 32.0]: box(Vector3(x, 3, 0), Vector3(0.8, 6, 64), concrete, true)
    box(Vector3(0, 0.8, -32), Vector3(64, 1.6, 0.7), concrete, true)
    var paint := material(Color("c8c5a4"), 0.05, 0.48)
    var yellow := material(Color("c3a34c"), 0.08, 0.5)
    for z in range(-29, 30, 5):
        for x in [-0.22, 0.22]: box(Vector3(x, 0.012, z), Vector3(0.13, 0.018, 2.6), yellow)
    for z in [-16.0, 16.0]:
        for x in range(-10, 11, 2): box(Vector3(x, 0.016, z), Vector3(1, 0.02, 3.0), paint)
        box(Vector3(0, 0.018, z + 2.2), Vector3(22, 0.02, 0.22), paint)
    for x in [-10.8, 10.8]: box(Vector3(x, 0.012, 0), Vector3(0.12, 0.018, 59), paint)
    label("FALSE CREEK  /  EVACUATION SECTOR 04", Vector3(0, 3.4, 31.5), 55, Color("ffbc7b"), PI)

func _buildings() -> void:
    var brick := pbr("brick_wall_04", 0.25)
    var stone := pbr("concrete_wall_006", 0.3)
    var trim := material(Color("303c43"), 0.45, 0.38)
    var warm := window_material(Color("ffc48c"), 2.5)
    var cool := window_material(Color("95c6da"), 1.4)
    var names := ["CEDAR & SALT", "PACIFIC PHARMACY", "NORTH SHORE COFFEE", "HARBOUR SUPPLY", "RAIN CITY RECORDS", "SEAWALL MARKET"]
    var n := 0
    for side in [-1.0, 1.0]:
        for z in [-23.0, -7.0, 11.0]:
            var x: float = side * 25.0
            var height := seeded.randf_range(14, 25)
            building_specs.append({"side":side,"z":z,"height":height})
            box(Vector3(x, height / 2, z), Vector3(13, height, 13), brick if n % 2 == 0 else stone, true)
            var face: float = side * 18.45
            box(Vector3(face, 1.9, z), Vector3(0.12, 3.4, 11.8), glass)
            box(Vector3(side * 17.9, 3.8, z), Vector3(1.3, 0.24, 13.5), metal)
            box(Vector3(side * 18.0, 4.5, z), Vector3(0.35, 1.0, 12), metal)
            label(names[n], Vector3(side * 17.77, 4.5, z), 34, Color("ffca8c") if n % 2 == 0 else Color("8fd6e1"), -side * PI / 2)
            for floor_y in range(6, int(height) - 1, 3):
                box(Vector3(face, floor_y - 1.2, z), Vector3(0.2, 0.16, 13), trim)
                # Actual window/frame modules are instanced by city_detail.gd.
                pass
            for dz in [-5.5, -2.8, 0.0, 2.8, 5.5]:
                box(Vector3(face - side * 0.1, 1.8, z + dz), Vector3(0.18, 3.4, 0.12), trim)
            box(Vector3(x, height + 0.2, z), Vector3(13.7, 0.4, 13.7), trim)
            box(Vector3(x + 2, height + 1, z), Vector3(3, 1.6, 3), metal)
            n += 1
    # Distant towers with lit window strips, no collision.
    for i in range(24):
        var x := -100.0 + i * 8.5
        var z := seeded.randf_range(-126, -96)
        var h := seeded.randf_range(20, 65)
        box(Vector3(x, h / 2 - 3, z), Vector3(6.5, h, 7), metal)
        for y in range(3, int(h) - 4, 3):
            for dx in [-2.0, 0.0, 2.0]:
                if seeded.randf() > 0.3: box(Vector3(x + dx, y, z + 3.55), Vector3(0.8, 0.8, 0.05), warm if i % 3 else cool)
        box(Vector3(x, h - 2, z), Vector3(0.2, 2.5, 0.2), concrete)
        box(Vector3(x, h - 0.65, z), Vector3(0.25, 0.25, 0.25), amber)

func _props() -> void:
    for x in [-13.8, 13.8]:
        for z in [-23.0, -3.0, 23.0]:
            box(Vector3(x, 3.3, z), Vector3(0.14, 6.6, 0.14), metal, true)
            box(Vector3(x - signf(x) * 0.8, 6.5, z), Vector3(1.8, 0.12, 0.12), metal)
            box(Vector3(x - signf(x) * 1.5, 6.4, z), Vector3(0.65, 0.13, 0.4), amber)
            var light := OmniLight3D.new()
            light.position = Vector3(x - signf(x) * 1.5, 5.9, z)
            light.light_color = Color("ffac63")
            light.light_energy = 5.0
            light.light_volumetric_fog_energy = 1.8
            light.omni_range = 17
            light.shadow_enabled = false
            add_child(light)
    # Detailed bus visual is built separately; keep the proven collision footprint.
    box(Vector3(-8.6, 1.65, 1), Vector3(2.8, 2.8, 9.5), null, true)
    # Bus shelter.
    box(Vector3(15.5, 2.7, 5), Vector3(3.5, 0.15, 5), metal)
    for z in [2.7, 7.3]: box(Vector3(16.7, 1.35, z), Vector3(0.1, 2.7, 0.1), metal, true)
    box(Vector3(16.7, 1.4, 5), Vector3(0.08, 2.5, 4.3), glass, true)
    box(Vector3(15.7, 0.6, 5), Vector3(0.7, 0.15, 2.8), concrete, true)
    label("04 / SEAWALL\nSERVICE SUSPENDED", Vector3(15.4, 2.2, 7.4), 26, Color("91dbe3"))
    # Street signs and traffic signals.
    for x in [-12.5, 12.5]:
        box(Vector3(x, 2.8, -13), Vector3(0.13, 5.6, 0.13), metal, true)
        box(Vector3(x, 5.3, -12.9), Vector3(3.9, 0.8, 0.12), material(Color("17494a")))
        label("PACIFIC BLVD", Vector3(x, 5.3, -12.81), 31)
        box(Vector3(x, 4, -12.8), Vector3(0.5, 1.1, 0.3), metal)
        box(Vector3(x, 4.3, -12.6), Vector3(0.25, 0.25, 0.04), emissive(Color("ed593e"), 2.0))
    # Waist-high barriers and small rubble in side bays, not random spawn blockers.
    for p in [Vector3(6, 0.6, -7), Vector3(5, 0.6, 22), Vector3(-5, 0.6, -22)]:
        box(p, Vector3(3.5, 1.2, 0.8), null, true)
        for dx in [-1.2, 0.0, 1.2]: box(p + Vector3(dx, 0.12, 0.42), Vector3(0.5, 0.3, 0.04), amber)
    for i in range(24):
        var p := Vector3(seeded.randf_range(13, 17) * (-1 if i % 2 else 1), 0.07, seeded.randf_range(-28, 28))
        box(p, Vector3(0.3, 0.14, 0.4), concrete)
    _flag(Vector3(-16, 6, -20))
    _flag(Vector3(16, 6, 19))

func _flag(pos: Vector3) -> void:
    box(pos - Vector3(0, 2.5, 0), Vector3(0.08, 6, 0.08), metal)
    var white := material(Color("d3d7d2"))
    var red := material(Color("b83234"))
    box(pos + Vector3(1, 0, 0), Vector3(2, 1, 0.025), white)
    for x in [0.25, 1.75]: box(pos + Vector3(x, 0, 0.02), Vector3(0.5, 1, 0.03), red)
    # Original stylized maple leaf, built as a double-sided flat mesh.
    var outline := PackedVector2Array([Vector2(0,-0.39), Vector2(0.09,-0.17), Vector2(0.21,-0.25), Vector2(0.18,-0.04), Vector2(0.34,-0.1), Vector2(0.28,0.03), Vector2(0.37,0.08), Vector2(0.1,0.22), Vector2(0.04,0.18), Vector2(0.04,0.38), Vector2(-0.04,0.38), Vector2(-0.04,0.18), Vector2(-0.1,0.22), Vector2(-0.37,0.08), Vector2(-0.28,0.03), Vector2(-0.34,-0.1), Vector2(-0.18,-0.04), Vector2(-0.21,-0.25), Vector2(-0.09,-0.17)])
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for index in Geometry2D.triangulate_polygon(outline):
        var v := outline[index]
        st.add_vertex(pos + Vector3(1 + v.x, -v.y, 0.045))
    st.generate_normals()
    var leaf := MeshInstance3D.new()
    leaf.mesh = st.commit()
    var leaf_mat := red.duplicate() as StandardMaterial3D
    leaf_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    leaf.material_override = leaf_mat
    add_child(leaf)

func _waterfront() -> void:
    var water_mat := ShaderMaterial.new()
    water_mat.shader = WET
    wet_textures(water_mat)
    water_mat.set_shader_parameter("water", 1.0)
    water_mat.set_shader_parameter("base_color", Color("163747"))
    box(Vector3(0, -1.1, -70), Vector3(230, 0.1, 75), water_mat)
    for x in range(-30, 31, 3): box(Vector3(x, 1.5, -31.9), Vector3(0.08, 1.4, 0.08), metal)
    box(Vector3(0, 2.1, -31.9), Vector3(62, 0.08, 0.08), metal)
    # Science World-inspired triangular geodesic landmark, across the water.
    var center := Vector3(-6, 12, -69)
    var sphere := SphereMesh.new()
    sphere.radius = 9
    sphere.height = 18
    sphere.radial_segments = 16
    sphere.rings = 8
    var orb := MeshInstance3D.new()
    orb.mesh = sphere
    orb.position = center
    orb.material_override = material(Color("172e47"), 0.5, 0.28)
    add_child(orb)
    var lines := ImmediateMesh.new()
    lines.surface_begin(Mesh.PRIMITIVE_LINES, cyan)
    for ring in range(1, 8):
        var a := PI * ring / 8.0
        var b := PI * (ring + 1) / 8.0
        for segment in range(16):
            var theta := TAU * segment / 16.0
            var next_theta := TAU * (segment + 1) / 16.0
            var p := center + Vector3(sin(a) * cos(theta), cos(a), sin(a) * sin(theta)) * 9.06
            var q := center + Vector3(sin(a) * cos(next_theta), cos(a), sin(a) * sin(next_theta)) * 9.06
            var r := center + Vector3(sin(b) * cos(theta), cos(b), sin(b) * sin(theta)) * 9.06
            var t := center + Vector3(sin(b) * cos(next_theta), cos(b), sin(b) * sin(next_theta)) * 9.06
            for vertex in [p, q, p, r, p, t]: lines.surface_add_vertex(vertex)
    lines.surface_end()
    var wire := MeshInstance3D.new()
    wire.mesh = lines
    add_child(wire)
    box(Vector3(-6, 2, -69), Vector3(25, 4, 19), concrete)
    label("FALSE CREEK / SCIENCE PAVILION", Vector3(-6, 3, -59.3), 48, Color("7acbdf"))
    # BC Place-inspired oval roof and cable masts.
    var stadium := MeshInstance3D.new()
    var roof := CylinderMesh.new()
    roof.top_radius = 15
    roof.bottom_radius = 18
    roof.height = 4
    roof.radial_segments = 32
    stadium.mesh = roof
    stadium.position = Vector3(25, 7, -84)
    stadium.scale.z = 0.65
    stadium.material_override = material(Color("82989e"), 0.25, 0.5)
    add_child(stadium)
    for i in range(16):
        var a := TAU * i / 16
        box(Vector3(25 + cos(a) * 16, 12, -84 + sin(a) * 10), Vector3(0.15, 10, 0.15), concrete)
        box(Vector3(25 + cos(a) * 16, 5.1, -84 + sin(a) * 10), Vector3(1.5, 0.7, 0.8), amber)
    # Layered North Shore silhouette.
    for i in range(13):
        var peak := MeshInstance3D.new()
        var cone := CylinderMesh.new()
        cone.top_radius = 0
        cone.bottom_radius = seeded.randf_range(22, 38)
        cone.height = seeded.randf_range(25, 48)
        cone.radial_segments = 5
        peak.mesh = cone
        peak.position = Vector3(-160 + i * 26, cone.height / 2 - 3, -175 - (i % 3) * 14)
        peak.material_override = material(Color("172a39"))
        add_child(peak)

func _weather() -> void:
    rain = CPUParticles3D.new()
    rain.amount = 420
    rain.lifetime = 1.0
    rain.preprocess = 1.0
    rain.local_coords = false
    rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
    rain.emission_box_extents = Vector3(11, 0.5, 11)
    rain.direction = Vector3(-0.15, -1, 0.03)
    rain.spread = 4
    rain.gravity = Vector3(0, -3, 0)
    rain.initial_velocity_min = 17
    rain.initial_velocity_max = 22
    var drop := BoxMesh.new()
    drop.size = Vector3(0.008, 0.28, 0.008)
    drop.material = material(Color("a9c0ce"), 0.0, 0.2)
    rain.mesh = drop
    rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(rain)

func follow_player(pos: Vector3) -> void:
    rain.global_position = pos + Vector3(0, 10, 0)

func set_quality(use_balanced: bool) -> void:
    balanced = use_balanced
    moon.shadow_enabled = balanced
    rain.amount = 420 if balanced else 160
    world.environment.fog_enabled = true
    world.environment.ssr_enabled = balanced
    world.environment.ssao_enabled = balanced
    world.environment.volumetric_fog_enabled = balanced
    get_viewport().scaling_3d_scale = 1.0 if balanced else 0.70
    get_viewport().use_taa = true
    # TAA stabilizes thin geometry and reflection edges; avoid stacking MSAA.
    get_viewport().msaa_3d = Viewport.MSAA_DISABLED

func _navigation() -> void:
    grid.region = Rect2i(-31, -31, 63, 63)
    grid.cell_size = Vector2.ONE
    grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
    grid.update()
    for x in range(-31, 32):
        for z in range(-31, 32):
            for obstacle in obstacles:
                if obstacle.has_point(Vector2(x, z)):
                    grid.set_point_solid(Vector2i(x, z))
                    break

func nearest_cell(pos: Vector3) -> Vector2i:
    var cell := Vector2i(clampi(roundi(pos.x), -31, 31), clampi(roundi(pos.z), -31, 31))
    if not grid.is_point_solid(cell): return cell
    # Also handles a player jumping onto cover: hunt the closest accessible edge.
    for radius in range(1, 16):
        for dx in range(-radius, radius + 1):
            for dz in range(-radius, radius + 1):
                var candidate := cell + Vector2i(dx, dz)
                if grid.is_in_boundsv(candidate) and not grid.is_point_solid(candidate): return candidate
    return Vector2i.ZERO

func route(from: Vector3, to: Vector3) -> PackedVector2Array:
    return grid.get_point_path(nearest_cell(from), nearest_cell(to))

func choose_spawn(player_pos: Vector3, index: int) -> Vector3:
    var candidates: Array[Vector3] = []
    for point in spawn_points:
        if point.distance_to(player_pos) > 15: candidates.append(point)
    if candidates.is_empty():
        var farthest := spawn_points[0]
        for point in spawn_points:
            if point.distance_squared_to(player_pos) > farthest.distance_squared_to(player_pos): farthest = point
        return farthest
    return candidates[index % candidates.size()]

func pbr(asset: String, repeat_scale: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    var path := "res://assets/materials/" + asset + "/"
    mat.albedo_texture = load(path + "diff.jpg")
    mat.normal_enabled = true
    mat.normal_texture = load(path + "nor_gl.jpg")
    mat.roughness_texture = load(path + "rough.jpg")
    mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
    mat.uv1_triplanar = true
    mat.uv1_world_triplanar = true
    mat.uv1_scale = Vector3.ONE * repeat_scale
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    return mat

func wet_textures(mat: ShaderMaterial) -> void:
    mat.set_shader_parameter("asphalt_color", preload("res://assets/materials/asphalt_02/diff.jpg"))
    mat.set_shader_parameter("asphalt_normal", preload("res://assets/materials/asphalt_02/nor_gl.jpg"))
    mat.set_shader_parameter("asphalt_roughness", preload("res://assets/materials/asphalt_02/rough.jpg"))

func window_material(color: Color, energy: float) -> ShaderMaterial:
    var mat := ShaderMaterial.new()
    mat.shader = preload("res://shaders/window.gdshader")
    mat.set_shader_parameter("glow_color", color)
    mat.set_shader_parameter("energy", energy)
    return mat
