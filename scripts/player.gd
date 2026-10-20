extends CharacterBody3D

signal fired(ammo, max_ammo)
signal damaged(health)
signal died

var camera: Camera3D
var gun: Node3D
var flash: OmniLight3D
var muzzle_visual: MeshInstance3D
var health := 100.0
var mouse_sensitivity := 0.0022
var move_speed := 7.0
var sprint_speed := 10.5
var shot_timer := 0.0
var reload_timer := 0.0
var shoot_kick := 0.0
var ammo := 12
var mag_size := 12
var damage := 30.0
var fire_delay := 0.33
var weapon_level := 1
var dead := false
var bob := 0.0
var game: Node3D

func _ready() -> void:
    collision_layer = 2
    collision_mask = 1
    var shape := CollisionShape3D.new()
    var cap := CapsuleShape3D.new()
    cap.radius = 0.38
    cap.height = 1.8
    shape.shape = cap
    shape.position.y = 0.9
    add_child(shape)
    camera = Camera3D.new()
    camera.position.y = 1.65
    camera.current = true
    camera.fov = 78
    add_child(camera)
    _build_gun()
    var fill := OmniLight3D.new()
    fill.position = Vector3(0, 0.2, 0.1)
    fill.light_color = Color("91abc2")
    fill.light_energy = 0.7
    fill.omni_range = 1.8
    camera.add_child(fill)
    var torch := SpotLight3D.new()
    torch.position = Vector3(0.3, -0.15, -0.3)
    torch.light_color = Color("c7d4db")
    torch.light_energy = 1.2
    torch.spot_range = 24
    torch.spot_angle = 27
    torch.spot_angle_attenuation = 1.8
    camera.add_child(torch)
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_gun() -> void:
    gun = Node3D.new()
    gun.position = Vector3(0.44, -0.39, -0.75)
    camera.add_child(gun)
    preload("res://scripts/weapon_visual.gd").build(gun)
    flash = OmniLight3D.new()
    flash.position = Vector3(0, 0, -0.82)
    flash.light_color = Color(1.0, 0.53, 0.16)
    flash.light_energy = 4.0
    flash.omni_range = 5.5
    flash.visible = false
    gun.add_child(flash)
    muzzle_visual = MeshInstance3D.new()
    var flare := QuadMesh.new()
    flare.size = Vector2(0.45, 0.45)
    muzzle_visual.mesh = flare
    var flare_material := ShaderMaterial.new()
    flare_material.shader = preload("res://shaders/muzzle_flash.gdshader")
    muzzle_visual.material_override = flare_material
    muzzle_visual.position = Vector3(0, -0.01, -0.91)
    muzzle_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    muzzle_visual.visible = false
    gun.add_child(muzzle_visual)

func _gun_part(pos: Vector3, size: Vector3, mat: Material) -> void:
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.material_override = mat
    mesh.position = pos
    gun.add_child(mesh)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not dead:
        rotate_y(-event.relative.x * mouse_sensitivity)
        camera.rotate_x(-event.relative.y * mouse_sensitivity)
        camera.rotation.x = clampf(camera.rotation.x, -1.45, 1.45)
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
    if event is InputEventKey and event.pressed and event.keycode == KEY_R:
        reload()
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
    if dead:
        return
    shot_timer -= delta
    if reload_timer > 0:
        reload_timer -= delta
        if reload_timer <= 0:
            ammo = mag_size
            fired.emit(ammo, mag_size)
    var axis := Vector2.ZERO
    if Input.is_key_pressed(KEY_A): axis.x -= 1
    if Input.is_key_pressed(KEY_D): axis.x += 1
    if Input.is_key_pressed(KEY_W): axis.y -= 1
    if Input.is_key_pressed(KEY_S): axis.y += 1
    axis = axis.normalized()
    var direction := global_transform.basis * Vector3(axis.x, 0, axis.y)
    var speed := sprint_speed if Input.is_key_pressed(KEY_SHIFT) else move_speed
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed
    if not is_on_floor():
        velocity.y -= 24.0 * delta
    else:
        velocity.y = -0.6
        if Input.is_key_pressed(KEY_SPACE):
            velocity.y = 8.5
    move_and_slide()
    bob += delta * axis.length() * speed * 1.5
    shoot_kick = lerpf(shoot_kick, 0.0, delta * 12)
    gun.position = Vector3(0.44 + sin(bob) * 0.007, -0.39 + abs(cos(bob)) * 0.008, -0.75 + shoot_kick)
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        shoot()

func shoot() -> void:
    if dead or shot_timer > 0 or reload_timer > 0:
        return
    if ammo <= 0:
        reload()
        return
    shot_timer = fire_delay
    ammo -= 1
    fired.emit(ammo, mag_size)
    shoot_kick = 0.13
    flash.visible = true
    muzzle_visual.visible = true
    muzzle_visual.rotation.z = randf_range(-PI, PI)
    get_tree().create_timer(0.07).timeout.connect(_hide_flash)
    var origin := camera.global_position
    var end := origin - camera.global_transform.basis.z * 90.0
    var query := PhysicsRayQueryParameters3D.create(origin, end)
    query.collision_mask = 5
    query.exclude = [get_rid()]
    var result := get_world_3d().direct_space_state.intersect_ray(query)
    if result and result.collider.is_in_group("zombies"):
        result.collider.take_hit(damage, result.position)
    if ammo == 0:
        reload()

func _hide_flash() -> void:
    if is_instance_valid(flash):
        flash.visible = false
        muzzle_visual.visible = false

func reload() -> void:
    if dead or reload_timer > 0 or ammo == mag_size:
        return
    reload_timer = 1.25

func upgrade() -> void:
    weapon_level += 1
    damage += 10.0
    mag_size += 5
    fire_delay = maxf(0.075, fire_delay * 0.84)
    reload_timer = 0.0
    ammo = mag_size
    fired.emit(ammo, mag_size)
    gun.scale = Vector3.ONE * (1.0 + minf((weapon_level - 1) * 0.025, 0.2))

func take_damage(amount: float) -> void:
    if dead:
        return
    health = maxf(0, health - amount)
    damaged.emit(health)
    if health <= 0:
        dead = true
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        died.emit()
