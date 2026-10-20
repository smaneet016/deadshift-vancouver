extends Node3D
## Authored detail pass plus CC0 scanned props. Gameplay collision stays in downtown.gd.
var city
var metal: Material
var rubber: Material
var warm: Material
var white: Material
var random := RandomNumberGenerator.new()
var module_records: Array[MeshInstance3D] = []

func build(level: Node3D) -> void:
    city = level
    random.seed = 20261019
    metal = city.material(Color("20292b"), 0.8, 0.3)
    rubber = city.material(Color("101416"), 0.05, 0.93)
    warm = city.emissive(Color("ff9741"), 5.0)
    white = city.emissive(Color("d8e9ff"), 4.0)
    _scanned_props()
    _bus()
    _gantry()
    _shopfronts()
    _imported_facades()
    _towers()
    _glass_upper_floors()
    _litter()
    _trees()
    _emergency_scene()
    _landmark_lights()
    _street_fire(Vector3(-14.5,0,-18))
    var probe := ReflectionProbe.new()
    probe.position = Vector3(0, 5, -5)
    probe.size = Vector3(63, 24, 76)
    probe.origin_offset = Vector3(0, 2, 0)
    probe.box_projection = true
    probe.max_distance = 150
    probe.intensity = 0.8
    probe.update_mode = ReflectionProbe.UPDATE_ONCE
    add_child(probe)
    _batch_modules()
    preload("res://scripts/visual_meshes.gd").batch_static(self)

func mesh(shape: Mesh, pos: Vector3, mat: Material, scale_xyz := Vector3.ONE, rot := Vector3.ZERO) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.mesh = shape
    item.material_override = mat
    item.position = pos
    item.scale = scale_xyz
    item.rotation = rot
    add_child(item)
    return item

func cylinder(a: Vector3, b: Vector3, radius: float, mat: Material, top := -1.0) -> MeshInstance3D:
    var shape := CylinderMesh.new()
    shape.top_radius = radius if top < 0 else top
    shape.bottom_radius = radius
    shape.height = a.distance_to(b)
    shape.radial_segments = 12
    var item := mesh(shape, (a + b) * 0.5, mat)
    var direction := (b - a).normalized()
    var axis := Vector3.UP.cross(direction)
    if axis.length() > 0.001: item.quaternion = Quaternion(axis.normalized(), acos(clampf(Vector3.UP.dot(direction), -1, 1)))
    elif direction.y < 0: item.rotation.x = PI
    return item

func sphere(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
    var shape := SphereMesh.new()
    shape.radius = 0.5
    shape.height = 1
    shape.radial_segments = 16
    shape.rings = 8
    return mesh(shape, pos, mat, size)

func scanned(asset: String, pos: Vector3, dimensions: Vector3, yaw := 0.0) -> void:
    var source: PackedScene = load("res://assets/models/" + asset + "/" + asset + ".gltf")
    var holder := Node3D.new()
    add_child(holder)
    var model := source.instantiate() as Node3D
    holder.add_child(model)
    var bounds := AABB()
    var found := false
    for child in model.find_children("*", "MeshInstance3D", true, false):
        var transform: Transform3D = holder.global_transform.affine_inverse() * child.global_transform
        var box: AABB = transform * child.get_aabb()
        bounds = bounds.merge(box) if found else box
        found = true
    if not found: return
    model.scale = dimensions / bounds.size
    model.position = -(bounds.position + Vector3(bounds.size.x / 2, 0, bounds.size.z / 2)) * model.scale
    holder.position = pos
    holder.rotation.y = yaw

func _scanned_props() -> void:
    for p in [Vector3(6, 0, -7), Vector3(5, 0, 22), Vector3(-5, 0, -22)]:
        scanned("concrete_road_barrier", p, Vector3(3.5, 1.2, 0.8))
    for p in [Vector3(-15.5, 0, -17), Vector3(15.5, 0, 14)]:
        scanned("fire_hydrant", p, Vector3(0.55, 0.9, 0.55))
    for p in [Vector3(17.4, 0, -17), Vector3(-17.4, 0, 7), Vector3(17.4, 0, 26)]:
        scanned("metal_trash_can", p, Vector3(0.6, 1.0, 0.6))
        for i in range(2): scanned("trashbag", p + Vector3(0.7 + i * 0.4, 0, -0.3), Vector3(0.55, 0.65, 0.5), i * 1.7)
    for p in [Vector3(-15.7, 0, -25), Vector3(15.7, 0, -25)]:
        scanned("street_lamp_01", p, Vector3(0.8, 6.7, 0.8))

func _bus() -> void:
    var paint: Material = city.pbr("concrete_wall_006", 0.8)
    paint.albedo_color = Color("818b8a")
    paint.roughness = 0.35
    paint.metallic = 0.4
    var blue: Material = city.material(Color("163c51"), 0.45, 0.3)
    var window: Material = city.material(Color("0a151b"), 0.6, 0.12)
    var frame: Material = city.material(Color("596366"), 0.85, 0.25)
    var origin := Vector3(-8.6, 0, 1)
    city.box(origin + Vector3(0, 1.15, 0), Vector3(2.72, 1.25, 9.4), paint)
    city.box(origin + Vector3(0, 2.8, 0), Vector3(2.65, 0.25, 9.3), paint)
    city.box(origin + Vector3(0, 1.1, 0), Vector3(2.76, 0.38, 9.42), blue)
    city.box(origin + Vector3(0, 0.46, 0), Vector3(2.4, 0.2, 9.1), rubber)
    city.box(origin + Vector3(0, 2.0, 0), Vector3(2.58, 1.5, 9.16), window)
    for x in [-1.37, 1.37]:
        for z in [-4.1, -2.7, -1.3, 0.1, 1.5, 2.9, 4.3]:
            city.box(origin + Vector3(x, 2.15, z), Vector3(0.08, 1.35, 0.09), frame)
        city.box(origin + Vector3(x, 2.16, 0), Vector3(0.06, 0.035, 9.1), frame)
        city.box(origin + Vector3(x, 1.53, 0), Vector3(0.07, 0.065, 9.2), frame)
        for z in [-3.1, 3.1]:
            cylinder(origin + Vector3(x - 0.13, 0.57, z), origin + Vector3(x + 0.13, 0.57, z), 0.51, rubber)
            cylinder(origin + Vector3(x, 0.57, z), origin + Vector3(x + signf(x) * 0.15, 0.57, z), 0.27, frame)
            for bolt in range(8):
                var a := TAU * bolt / 8
                sphere(origin + Vector3(x + signf(x)*0.17, 0.57 + sin(a)*0.18, z + cos(a)*0.18), Vector3(0.035,0.035,0.035), metal)
        for z in [-3.5, -2.1, -0.7, 0.7, 2.1, 3.5]:
            city.box(origin + Vector3(x * 0.6, 1.7, z), Vector3(0.43, 0.6, 0.18), blue)
        for z in [-4.3, 4.3]:
            city.box(origin + Vector3(x, 2.77, z), Vector3(0.08, 0.08, 0.14), warm)
    city.box(origin + Vector3(0, 3.05, -1), Vector3(1.8, 0.25, 2.4), frame)
    for z in range(-20,21): city.box(origin + Vector3(0,3.19,z*0.045-1),Vector3(1.5,0.025,0.015),metal)
    for x in [-1.0, 1.0]:
        city.box(origin + Vector3(x, 0.95, 4.72), Vector3(0.42, 0.18, 0.07), white)
        city.box(origin + Vector3(x, 0.75, -4.72), Vector3(0.2, 0.25, 0.05), city.emissive(Color("cf2417"),3.0))
        cylinder(origin + Vector3(x*0.9,1.65,4.65),origin + Vector3(x*0.45,2.35,4.67),0.018,rubber)
    city.box(origin + Vector3(0, 0.53, 4.78), Vector3(2.75, 0.17, 0.18), frame)
    for x in range(-8,9): city.box(origin + Vector3(x*0.09,1.0,4.73),Vector3(0.025,0.3,0.04),rubber)
    city.box(origin + Vector3(0,2.7,4.72),Vector3(2.4,0.32,0.06),rubber)
    city.label("04  DOWNTOWN", origin + Vector3(0,2.7,4.77),25,Color("ffaf43"))
    city.label("COAST TRANSIT", origin+Vector3(1.395,1.13,0),21,Color("d2dbdc"),PI/2)
    for x in [-1.0,1.0]:
        var headlight := SpotLight3D.new()
        headlight.position = origin+Vector3(x,0.95,4.8)
        headlight.rotation.y = PI
        headlight.light_color = Color("b9d5ed")
        headlight.light_energy = 2.8
        headlight.spot_range = 17
        headlight.spot_angle = 38
        add_child(headlight)

func _gantry() -> void:
    for x in [-11.4, 11.4]:
        cylinder(Vector3(x,0,-12),Vector3(x,8,-12),0.11,metal)
    cylinder(Vector3(-11.4,7.8,-12),Vector3(11.4,7.8,-12),0.11,metal)
    var sign_mat: Material = city.material(Color("103a33"),0.35,0.35)
    for x in [-5.2,2.6]:
        city.box(Vector3(x,6.9,-11.9),Vector3(6.4,2.0,0.12),sign_mat)
        for y in [5.95,7.85]:city.box(Vector3(x,y,-11.82),Vector3(6.25,0.035,0.03),white)
        for edge in [-3.1,3.1]:city.box(Vector3(x+edge,6.9,-11.82),Vector3(0.035,1.9,0.03),white)
        city.box(Vector3(x,8.02,-11.65),Vector3(1.0,0.08,0.45),metal)
        var light:=OmniLight3D.new()
        light.position=Vector3(x,7.7,-11.1)
        light.light_color=Color("c3d6df")
        light.light_energy=0.7
        light.omni_range=3
        add_child(light)
    city.label("Main St",Vector3(-5.2,7.3,-11.78),70,Color("e0e5d7"))
    city.label("DOWNTOWN   ↓",Vector3(-5.2,6.45,-11.78),40,Color("d2dbca"))
    city.label("BC Place",Vector3(2.6,7.3,-11.78),70,Color("e0e5d7"))
    city.label("WATERFRONT   ↘",Vector3(2.6,6.45,-11.78),36,Color("d2dbca"))

func _shopfronts() -> void:
    var wood: Material=city.pbr("rusty_metal_02",0.6)
    var dark: Material=city.material(Color("0a1014"),0.45,0.2)
    for side in [-1.0,1.0]:
        for z in [-23.0,-7.0,11.0]:
            var face: float=side*18.25
            # Door frames, recessed entry and overhang edges.
            city.box(Vector3(face,1.4,z),Vector3(0.18,2.8,1.5),dark)
            for dz in [-0.8,0.8]:city.box(Vector3(face-side*0.1,1.4,z+dz),Vector3(0.18,2.8,0.06),metal)
            city.box(Vector3(face-side*0.15,1.2,z+0.55),Vector3(0.1,0.4,0.045),white)
            for dz in [-4.5,-3.7,3.7,4.5]:
                city.box(Vector3(face-side*0.13,1.2,z+dz),Vector3(0.08,1.7,0.45),wood)
            # Suspended shop sign and awning ribs.
            city.box(Vector3(face-side*1.6,4.0,z+4.8),Vector3(2.8,1.0,0.18),metal)
            city.label("OPEN 24H",Vector3(face-side*1.6,4.0,z+4.91),27,Color("ff9c5c"))
            for dz in range(-6,7):city.box(Vector3(face-side*0.45,3.67,z+dz),Vector3(1.3,0.06,0.035),metal)
            for y in [6.0,9.0,12.0]:
                cylinder(Vector3(face-side*0.2,y,z-5.8),Vector3(face-side*0.2,y+2.9,z-5.8),0.045,metal)
            var light:=OmniLight3D.new()
            light.position=Vector3(side*17,2.9,z)
            light.omni_range=7
            light.light_energy=1.8
            light.light_color=Color("ff8842") if z != -7 else Color("47b4bd")
            add_child(light)
    # Cable bundles sag across the street.
    for z in [-5.0,-26.0]:
        for cable in range(3):
            var previous:=Vector3(-18,9,z+cable*0.18)
            for i in range(1,17):
                var x:float=-18+i*2.25
                var next:=Vector3(x,7.2+1.8*pow(x/18,2),z+cable*0.18)
                cylinder(previous,next,0.016,rubber)
                previous=next
    # Thin curtains of amber lights along the distant waterfront edge.
    for x in range(-30,31,2):
        city.box(Vector3(x,2.8,-33),Vector3(0.08,0.08,0.08),warm)

func _towers() -> void:
    var shell: Material=city.material(Color("101e29"),0.75,0.22)
    var dark_glass: Material=city.material(Color("152b39"),0.7,0.2)
    var warm_window: Material=city.window_material(Color("ffcf92"),3.0)
    var cold_window: Material=city.window_material(Color("a9d0e3"),1.7)
    for i in range(18):
        var x:float=-73+i*8.4
        var z:float=-89-(i%3)*11
        var h:float=random.randf_range(23,53)
        city.box(Vector3(x,h/2,z),Vector3(6.3,h,6.5),shell)
        city.box(Vector3(x,h+1.3,z),Vector3(4.9,2.6,5.0),dark_glass)
        for y in range(2,int(h),2):
            city.box(Vector3(x,y,z+3.32),Vector3(6.4,0.06,0.14),metal)
            for dx in [-2.5,-1.5,-0.5,0.5,1.5,2.5]:
                city.box(Vector3(x+dx,y+0.65,z+3.31),Vector3(0.68,1.15,0.05),warm_window if random.randf()>0.6 else (cold_window if random.randf()>0.75 else dark_glass))
        for dx in [-3.0,0.0,3.0]:city.box(Vector3(x+dx,h/2,z+3.4),Vector3(0.08,h,0.08),metal)
        city.box(Vector3(x,h+3,z),Vector3(0.1,3.0,0.1),metal)
        city.box(Vector3(x,h+4.5,z),Vector3(0.12,0.12,0.12),city.emissive(Color("dc3029"),2))

func _trees() -> void:
    var bark: Material=city.pbr("concrete_wall_006",1.5)
    bark.albedo_color=Color("39312a")
    var leaves: Material=city.material(Color("282a16"),0.0,0.85)
    for x in [-16.7,16.7]:
        for z in [-18.0,18.0]:
            cylinder(Vector3(x,0,z),Vector3(x+0.2,4.8,z),0.16,bark,0.07)
            for i in range(9):
                var a:float=i*2.4
                var start:=Vector3(x,2.5+i*0.19,z)
                var end:=start+Vector3(cos(a)*1.7,1.0,sin(a)*1.4)
                cylinder(start,end,0.06,bark,0.018)
                # Small irregular leaf clusters rather than large spherical canopies.
                for j in range(5):
                    var p:=end+Vector3(random.randf_range(-0.7,0.7),random.randf_range(-0.2,0.6),random.randf_range(-0.6,0.6))
                    var leaf:=PrismMesh.new()
                    leaf.size=Vector3(0.55,0.25,0.55)
                    mesh(leaf,p,leaves,Vector3.ONE,Vector3(random.randf(),a,random.randf()))

func _emergency_scene() -> void:
    var burnt: Material=city.pbr("rusty_metal_02",0.9)
    var red: Material=city.emissive(Color("ef3023"),4)
    # Wrecked compact car in the southern side bay, outside primary spawn routes.
    var p:=Vector3(14.6,0,24)
    city.box(p+Vector3(0,0.7,0),Vector3(1.9,0.75,4.2),burnt)
    city.box(p+Vector3(0,1.25,-0.2),Vector3(1.65,0.7,2.1),metal)
    for x in [-0.95,0.95]:
        for z in [-1.3,1.3]:cylinder(p+Vector3(x-0.1,0.4,z),p+Vector3(x+0.1,0.4,z),0.36,rubber)
    for x in [-0.7,0.7]:city.box(p+Vector3(x,0.85,2.12),Vector3(0.3,0.17,0.04),red)
    # Small fire / smoke is intentionally decorative, not a damage volume.
    var flame_mat:=ShaderMaterial.new()
    flame_mat.shader=preload("res://shaders/fire.gdshader")
    var flame:=QuadMesh.new()
    flame.size=Vector2(1.5,2.2)
    mesh(flame,Vector3(14.6,1.7,25),flame_mat)
    var fire:=OmniLight3D.new()
    fire.position=Vector3(14.6,2,25)
    fire.light_color=Color("ff5f16")
    fire.light_energy=5
    fire.omni_range=12
    fire.light_volumetric_fog_energy=2
    add_child(fire)

func _glass_upper_floors() -> void:
    var facade: Material = city.material(Color("10212a"), 0.85, 0.19)
    var mullion: Material = city.material(Color("29353c"), 0.8, 0.3)
    var room: Material = city.window_material(Color("ffc78b"), 1.7)
    var room_cool: Material = city.window_material(Color("9bafbe"), 0.8)
    for side in [-1.0, 1.0]:
        for z in [-23.0, 11.0]:
            var height: float = 46 if z < 0 else 36
            city.box(Vector3(side*25, 24+height/2, z), Vector3(12.8,height,12.8), facade)
            for y in range(25,int(24+height),3):
                city.box(Vector3(side*18.54,y,z),Vector3(0.14,0.10,12.8),mullion)
                for dz in range(-5,6,2):
                    if random.randf()>0.73:
                        city.box(Vector3(side*18.5,y+1.4,z+dz),Vector3(0.03,2.2,1.35),room if random.randf()>0.4 else room_cool)
            for dz in range(-6,7,2):
                city.box(Vector3(side*18.48,24+height/2,z+dz),Vector3(0.18,height,0.08),mullion)
            city.box(Vector3(side*25,24+height,z),Vector3(13,0.3,13),mullion)

func _litter() -> void:
    var paper: Material = city.material(Color("696e68"),0,0.8)
    var torn: Material = city.pbr("rusty_metal_02",0.5)
    var broken: Material = city.pbr("concrete_wall_006",0.5)
    for i in range(90):
        var x: float = random.randf_range(-17,17)
        var z: float = random.randf_range(-29,29)
        if absf(x)<4 and i%3!=0:continue
        var sheet:=PrismMesh.new()
        sheet.size=Vector3(random.randf_range(0.12,0.4),0.012,random.randf_range(0.16,0.55))
        mesh(sheet,Vector3(x,0.025,z),paper if i%3 else torn,Vector3.ONE,Vector3(0,random.randf_range(-PI,PI),0))
    for side in [-1.0,1.0]:
        for z in [-10.0,13.0]:
            for i in range(8):
                var stone:=PrismMesh.new()
                stone.size=Vector3(random.randf_range(0.1,0.3),random.randf_range(0.08,0.2),random.randf_range(0.12,0.3))
                mesh(stone,Vector3(side*17+random.randf_range(-0.5,0.5),0.07,z+random.randf_range(-1,1)),broken,Vector3.ONE,Vector3(0,random.randf()*PI,0))

func _landmark_lights() -> void:
    var orb := SphereMesh.new()
    orb.radius = 0.11
    orb.height = 0.22
    orb.radial_segments = 8
    orb.rings = 4
    orb.material = city.emissive(Color("c5b7ff"),5.0)
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = orb
    mm.instance_count = 112
    for ring in range(1,8):
        var a: float = PI*ring/8.0
        for segment in range(16):
            var theta: float = TAU*segment/16.0
            var p := Vector3(-6,12,-69) + Vector3(sin(a)*cos(theta),cos(a),sin(a)*sin(theta))*9.1
            mm.set_instance_transform((ring-1)*16+segment,Transform3D(Basis.IDENTITY,p))
    var lights := MultiMeshInstance3D.new()
    lights.multimesh=mm
    lights.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(lights)
    var stadium_light: Material = city.emissive(Color("d66e86"),2.3)
    for i in range(64):
        var a: float = TAU*i/64.0
        city.box(Vector3(25+cos(a)*16,7.5,-84+sin(a)*10),Vector3(0.5,0.3,0.4),stadium_light)

func _street_fire(pos: Vector3) -> void:
    var flame_mat:=ShaderMaterial.new()
    flame_mat.shader=preload("res://shaders/fire.gdshader")
    var shape:=QuadMesh.new()
    shape.size=Vector2(1.3,2.3)
    for i in range(3):
        mesh(shape,pos+Vector3(i*0.2,1.1,i*0.1),flame_mat,Vector3.ONE,Vector3(0,(i-1)*0.6,0))
    var lamp:=OmniLight3D.new()
    lamp.position=pos+Vector3(0,1.7,0)
    lamp.light_color=Color("ff721f")
    lamp.light_energy=6
    lamp.omni_range=14
    lamp.light_volumetric_fog_energy=3
    add_child(lamp)
    var smoke:=CPUParticles3D.new()
    smoke.position=pos+Vector3(0,1.8,0)
    smoke.amount=18
    smoke.lifetime=4
    smoke.preprocess=4
    smoke.direction=Vector3(0,1,0)
    smoke.spread=18
    smoke.gravity=Vector3(0,0.2,0)
    smoke.initial_velocity_min=1.0
    smoke.initial_velocity_max=1.6
    smoke.scale_amount_min=0.8
    smoke.scale_amount_max=2
    var gradient:=Gradient.new()
    gradient.set_color(0,Color(0.18,0.19,0.2,0.22))
    gradient.set_color(1,Color(0.18,0.19,0.2,0))
    var texture:=GradientTexture2D.new()
    texture.gradient=gradient
    texture.fill=GradientTexture2D.FILL_RADIAL
    texture.fill_from=Vector2(0.5,0.5)
    texture.fill_to=Vector2(0.5,1)
    texture.width=64
    texture.height=64
    var smoke_mat:=StandardMaterial3D.new()
    smoke_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    smoke_mat.albedo_texture=texture
    smoke_mat.billboard_mode=BaseMaterial3D.BILLBOARD_PARTICLES
    var quad:=QuadMesh.new()
    quad.size=Vector2(2,2)
    quad.material=smoke_mat
    smoke.mesh=quad
    smoke.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(smoke)

func _module(kit: Node3D, module_name: String, position_world: Vector3, yaw: float, offset := Vector3.ZERO) -> Node3D:
    var source := kit.find_child(module_name, true, false) as Node3D
    if source == null:
        push_error("Missing facade module: " + module_name)
        return null
    var holder := Node3D.new()
    add_child(holder)
    var copy := source.duplicate() as Node3D
    holder.add_child(copy)
    copy.transform = Transform3D(Basis.IDENTITY, offset)
    holder.position = position_world
    holder.rotation.y = yaw
    if copy is MeshInstance3D: module_records.append(copy)
    return copy

func _imported_facades() -> void:
    var kit := (load("res://assets/models/modular_urban_apartments_facade/modular_urban_apartments_facade.gltf") as PackedScene).instantiate() as Node3D
    var fire_escape := (load("res://assets/models/modular_fire_escape/modular_fire_escape.gltf") as PackedScene).instantiate() as Node3D
    var doors := (load("res://assets/models/rollershutter_door/rollershutter_door.gltf") as PackedScene).instantiate() as Node3D
    var window_warm: Material = city.emissive(Color("d8a773"), 1.5)
    window_warm.roughness = 0.23
    var window_cold: Material = city.emissive(Color("75919e"), 0.75)
    for spec in city.building_specs:
        var side: float = spec.side
        var z: float = spec.z
        var height: float = spec.height
        var yaw: float = -side * PI/2
        for y in range(6,int(height)-1,3):
            for dz in [-4.5,-1.5,1.5,4.5]:
                var position_world := Vector3(side*18.30,y-1.2,z+dz)
                _module(kit,"wall_window_centered_large_01",position_world,yaw,Vector3(1.5,0,0))
                var window := _module(kit,"window_centered_large_01",position_world,yaw,Vector3(1.5,0,0)) as MeshInstance3D
                if window and window.mesh.get_surface_count() > 1 and random.randf()>0.5:
                    window.set_surface_override_material(1,window_warm if random.randf()>0.3 else window_cold)
                _module(kit,"cornice_standard_standard_01",position_world+Vector3(0,2.8,0),yaw,Vector3(1.5,0,0))
        if z == -7:
            for y in [5.0,9.0,13.0]:
                _module(fire_escape,"modular_fire_escape_platform_middle",Vector3(side*17.6,y,z),yaw)
                _module(fire_escape,"modular_fire_escape_railing_middle",Vector3(side*17.6,y+0.8,z),yaw)
                _module(fire_escape,"modular_fire_escape_stairs",Vector3(side*17.4,y-1.9,z),yaw)
        for dz in [-4.0,4.0]:
            _module(doors,"rollershutter_door",Vector3(side*18.02,0,z+dz),yaw)
    kit.free()
    fire_escape.free()
    doors.free()

func _batch_modules() -> void:
    var groups: Dictionary = {}
    for item in module_records:
        var key := str(item.mesh.get_instance_id())
        for surface in range(item.mesh.get_surface_count()):
            var active := item.get_active_material(surface)
            key += ":" + str(active.get_instance_id() if active else 0)
        if not groups.has(key): groups[key] = []
        groups[key].append(item)
    for key in groups:
        var items: Array = groups[key]
        var first: MeshInstance3D = items[0]
        var shared := first.mesh.duplicate() as ArrayMesh
        for surface in range(shared.get_surface_count()):
            shared.surface_set_material(surface, first.get_active_material(surface))
        var mm := MultiMesh.new()
        mm.transform_format = MultiMesh.TRANSFORM_3D
        mm.mesh = shared
        mm.instance_count = items.size()
        for i in range(items.size()):
            var item: MeshInstance3D = items[i]
            mm.set_instance_transform(i, global_transform.affine_inverse() * item.global_transform)
        var instance := MultiMeshInstance3D.new()
        instance.multimesh = mm
        add_child(instance)
        for item in items:
            var holder: Node = item.get_parent()
            remove_child(holder)
            holder.free()
    module_records.clear()
