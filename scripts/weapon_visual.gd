extends RefCounted
const V=preload("res://scripts/visual_meshes.gd")
static func mat(color:Color,metallic:float,rough:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color;m.metallic=metallic;m.roughness=rough
    return m
static func build(gun:Node3D)->void:
    var steel:=mat(Color("394249"),0.88,0.3)
    var dark:=mat(Color("11191e"),0.65,0.35)
    var edge:=mat(Color("667079"),0.9,0.24)
    var grip:=mat(Color("1d2528"),0.05,0.86)
    var glove:=mat(Color("42463e"),0.05,0.85)
    var sleeve:=mat(Color("263330"),0.0,0.9)
    # Machined receiver, upper rail and ventilated fore-end.
    V.box(gun,Vector3(0,0,-0.12),Vector3(0.14,0.17,0.42),steel,0.018)
    V.box(gun,Vector3(0,0.082,-0.17),Vector3(0.12,0.065,0.57),dark,0.012)
    V.box(gun,Vector3(0,-0.035,-0.45),Vector3(0.13,0.14,0.29),dark,0.02)
    for i in range(10):
        V.box(gun,Vector3(0,0.13,-0.43+i*0.052),Vector3(0.15,0.018,0.025),edge,0.003)
    for side in [-1.0,1.0]:
        for i in range(5):
            V.box(gun,Vector3(side*0.066,-0.015,-0.55+i*0.047),Vector3(0.004,0.05,0.025),grip,0.002)
        for z in [-0.26,-0.07,0.04]:
            V.rod(gun,Vector3(side*0.07,0.02,z),Vector3(side*0.077,0.02,z),0.009,edge)
    V.box(gun,Vector3(0.073,0.026,-0.15),Vector3(0.009,0.048,0.105),grip,0.004)
    V.box(gun,Vector3(0.08,0.05,-0.02),Vector3(0.065,0.02,0.025),edge,0.004)
    # Barrel, muzzle brake and visible bore.
    V.rod(gun,Vector3(0,-0.01,-0.57),Vector3(0,-0.01,-0.78),0.025,edge)
    V.rod(gun,Vector3(0,-0.01,-0.75),Vector3(0,-0.01,-0.86),0.039,dark)
    for z in [-0.77,-0.8,-0.83]:V.rod(gun,Vector3(0,-0.01,z),Vector3(0,-0.01,z-0.009),0.041,edge)
    V.rod(gun,Vector3(0,-0.01,-0.861),Vector3(0,-0.01,-0.865),0.018,grip)
    # Magazine, pistol grip, trigger guard and stock.
    V.box(gun,Vector3(0,-0.22,-0.14),Vector3(0.10,0.29,0.13),dark,0.015,Vector3(-0.15,0,0))
    for i in range(4):V.box(gun,Vector3(0.052,-0.18-i*0.035,-0.14),Vector3(0.009,0.01,0.10),edge,0.002)
    V.box(gun,Vector3(0,-0.17,0.065),Vector3(0.095,0.20,0.11),grip,0.02,Vector3(-0.25,0,0))
    V.box(gun,Vector3(0,-0.12,-0.025),Vector3(0.075,0.025,0.13),steel,0.006)
    V.box(gun,Vector3(0,-0.07,-0.075),Vector3(0.075,0.11,0.02),steel,0.004)
    V.box(gun,Vector3(0,-0.01,0.22),Vector3(0.10,0.12,0.25),dark,0.02)
    # Reflex sight hood, open centre and small red emitter.
    V.box(gun,Vector3(0,0.17,-0.04),Vector3(0.12,0.04,0.11),dark,0.008)
    for x in [-0.055,0.055]:V.box(gun,Vector3(x,0.23,-0.04),Vector3(0.018,0.12,0.095),steel,0.005)
    V.box(gun,Vector3(0,0.29,-0.04),Vector3(0.12,0.018,0.095),steel,0.006)
    var led:=mat(Color("f34e25"),0.0,0.4)
    led.emission_enabled=true;led.emission=Color("f34e25");led.emission_energy_multiplier=2
    V.ellipsoid(gun,Vector3(0,0.19,-0.01),Vector3(0.01,0.01,0.01),led)
    # Gloved support hand and sleeve, with articulated finger silhouettes.
    V.ellipsoid(gun,Vector3(-0.03,-0.13,-0.45),Vector3(0.15,0.12,0.17),glove)
    V.rod(gun,Vector3(-0.03,-0.19,-0.43),Vector3(-0.24,-0.38,-0.18),0.08,sleeve,0.105)
    for i in range(4):V.rod(gun,Vector3(-0.075,-0.07,-0.5+i*0.028),Vector3(0.04,-0.085,-0.5+i*0.028),0.019,glove)
    V.ellipsoid(gun,Vector3(0.04,-0.18,0.07),Vector3(0.14,0.17,0.14),glove)
    V.rod(gun,Vector3(0.04,-0.24,0.1),Vector3(0.22,-0.39,0.36),0.075,sleeve,0.1)
    V.batch_static(gun)
