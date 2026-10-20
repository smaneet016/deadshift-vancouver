extends RefCounted
const V=preload("res://scripts/visual_meshes.gd")
static func material(color:Color,rough:=0.85)->StandardMaterial3D:
    var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=rough
    return m
static func build(zombie:Node3D)->void:
    var skin:=material(Color("6e7060") if zombie.variant%2==0 else Color("807065"),0.65)
    var cloth:=material(Color("3b4944") if zombie.variant%3==0 else Color("49413b"))
    cloth.normal_enabled=true
    cloth.normal_texture=preload("res://assets/materials/concrete_wall_006/nor_gl.jpg")
    cloth.normal_scale=0.25
    var pants:=material(Color("222e35"))
    var blood:=material(Color("471b17"),0.3)
    var black:=material(Color("111314"))
    zombie.clothing_color=cloth.albedo_color
    zombie.body_mesh=V.ellipsoid(zombie,Vector3(0,1.18,0),Vector3(0.49,0.64,0.3),cloth)
    V.ellipsoid(zombie,Vector3(0,0.85,0),Vector3(0.36,0.29,0.27),pants)
    V.rod(zombie,Vector3(0,1.4,0),Vector3(0,1.58,-0.03),0.075,skin)
    zombie.head_mesh=V.ellipsoid(zombie,Vector3(0,1.69,-0.035),Vector3(0.28,0.35,0.26),skin)
    # Brow ridges, jaw, ears and open mouth break the mannequin silhouette.
    V.ellipsoid(zombie,Vector3(0,1.58,-0.085),Vector3(0.20,0.14,0.20),skin)
    V.ellipsoid(zombie,Vector3(0,1.65,-0.17),Vector3(0.055,0.08,0.075),skin)
    V.ellipsoid(zombie,Vector3(0,1.58,-0.178),Vector3(0.11,0.047,0.025),black)
    for side in [-1.0,1.0]:
        V.ellipsoid(zombie,Vector3(side*0.14,1.68,-0.03),Vector3(0.045,0.085,0.04),skin)
        V.ellipsoid(zombie,Vector3(side*0.065,1.73,-0.15),Vector3(0.1,0.035,0.045),blood)
        V.ellipsoid(zombie,Vector3(side*0.065,1.76,-0.13),Vector3(0.12,0.045,0.08),skin)
        # Pivoted legs and arms allow an actual walking silhouette.
        var leg:=Node3D.new();zombie.add_child(leg);leg.position=Vector3(side*0.13,0.84,0)
        zombie.leg_pivots.append(leg)
        V.rod(leg,Vector3.ZERO,Vector3(side*0.015,-0.37,0.025),0.105,pants,0.13)
        V.rod(leg,Vector3(side*0.015,-0.37,0.025),Vector3(side*0.015,-0.71,0),0.07,pants,0.10)
        V.ellipsoid(leg,Vector3(side*0.015,-0.76,-0.055),Vector3(0.15,0.14,0.29),black)
        var arm:=Node3D.new();zombie.add_child(arm);arm.position=Vector3(side*0.25,1.4,0)
        zombie.arm_pivots.append(arm)
        V.ellipsoid(arm,Vector3.ZERO,Vector3(0.23,0.25,0.24),cloth)
        V.rod(arm,Vector3.ZERO,Vector3(side*0.07,-0.3,-0.07),0.065,cloth,0.10)
        V.rod(arm,Vector3(side*0.07,-0.3,-0.07),Vector3(side*0.065,-0.53,-0.22),0.045,skin,0.07)
        V.ellipsoid(arm,Vector3(side*0.065,-0.56,-0.23),Vector3(0.10,0.15,0.06),skin)
        for finger in range(4):
            V.rod(arm,Vector3(side*0.065+(finger-1.5)*0.022,-0.61,-0.24),Vector3(side*0.065+(finger-1.5)*0.024,-0.70,-0.27),0.011,skin)
    var eye:=material(Color("a89966"),0.22)
    eye.emission_enabled=true;eye.emission=Color("ff8b43");eye.emission_energy_multiplier=0.7
    zombie.eye_left=V.ellipsoid(zombie,Vector3(-0.063,1.72,-0.17),Vector3(0.035,0.018,0.016),eye)
    zombie.eye_right=V.ellipsoid(zombie,Vector3(0.063,1.72,-0.17),Vector3(0.035,0.018,0.016),eye)
    # Torn collar, shirt seam and irregular wound patches.
    for side in [-1.0,1.0]:
        V.box(zombie,Vector3(side*0.08,1.42,-0.12),Vector3(0.1,0.12,0.025),cloth,0.008,Vector3(0,0,side*0.4))
    V.rod(zombie,Vector3(0,0.96,-0.145),Vector3(0,1.37,-0.155),0.009,black)
    V.ellipsoid(zombie,Vector3(-0.12,1.21,-0.14),Vector3(0.16,0.25,0.018),blood)
    V.ellipsoid(zombie,Vector3(0.08,1.82,-0.09),Vector3(0.1,0.09,0.05),blood)
    for pivot in zombie.arm_pivots: V.batch_static(pivot)
    for pivot in zombie.leg_pivots: V.batch_static(pivot)
    V.batch_static(zombie, [zombie.body_mesh, zombie.head_mesh, zombie.eye_left, zombie.eye_right])
