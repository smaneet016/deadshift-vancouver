extends CharacterBody3D

signal killed(zombie)

var target: CharacterBody3D
var health := 60.0
var speed := 2.4
var damage := 11.0
var attack_cooldown := 0.0
var alive := true
var anim_time := 0.0
var body_mesh: MeshInstance3D
var head_mesh: MeshInstance3D
var eye_left: MeshInstance3D
var eye_right: MeshInstance3D
var variant := 0
var level: Node3D
var path := PackedVector2Array()
var path_index := 0
var repath_timer := 0.0
var hit_tween: Tween
var clothing_color: Color
var arm_pivots: Array[Node3D] = []
var leg_pivots: Array[Node3D] = []

func _ready() -> void:
    add_to_group("zombies")
    collision_layer = 4
    collision_mask = 1
    repath_timer = float(variant % 7) * 0.07
    _build_body()

func _build_body() -> void:
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.36
    capsule.height = 1.8
    var collision := CollisionShape3D.new()
    collision.shape = capsule
    collision.position.y = 0.9
    add_child(collision)
    preload("res://scripts/zombie_visual.gd").build(self)

func _part(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.material_override = mat
    mesh.position = pos
    add_child(mesh)
    return mesh

func _physics_process(delta: float) -> void:
    if not alive or not is_instance_valid(target) or target.dead:
        return
    anim_time += delta
    attack_cooldown -= delta
    var toward := target.global_position - global_position
    toward.y = 0
    var dist := toward.length()
    repath_timer -= delta
    if is_instance_valid(level) and repath_timer <= 0:
        path = level.route(global_position, target.global_position)
        path_index = 0
        repath_timer = 0.55 + float(variant % 5) * 0.03
    var hunt := toward
    if path.size() > 0:
        var here := Vector2(global_position.x, global_position.z)
        while path_index < path.size() - 1 and here.distance_to(path[path_index]) < 0.6:
            path_index += 1
        hunt = Vector3(path[path_index].x - global_position.x, 0, path[path_index].y - global_position.z)
    var clear_attack := false
    if dist <= 1.35 and absf(target.global_position.y - global_position.y) < 1.8:
        var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, target.global_position + Vector3.UP, 1)
        clear_attack = get_world_3d().direct_space_state.intersect_ray(query).is_empty()
    if dist > 0.05:
        var dir := hunt.normalized()
        rotation.y = atan2(-dir.x, -dir.z)
        if not clear_attack:
            velocity.x = dir.x * speed
            velocity.z = dir.z * speed
        else:
            velocity.x = 0
            velocity.z = 0
            if attack_cooldown <= 0:
                target.take_damage(damage)
                attack_cooldown = 1.3
    if not is_on_floor():
        velocity.y -= 24.0 * delta
    else:
        velocity.y = -0.5
    move_and_slide()
    for i in range(leg_pivots.size()):
        var stride := sin(anim_time * 6.5 + i * PI)
        leg_pivots[i].rotation.x = stride * 0.35 if velocity.length() > 0.7 else 0.0
        arm_pivots[i].rotation.x = -0.35 - stride * 0.16
    body_mesh.rotation.z = sin(anim_time * 8) * 0.035
    head_mesh.rotation.z = sin(anim_time * 3.4) * 0.07

func take_hit(amount: float, _hit_pos: Vector3) -> void:
    if not alive:
        return
    health -= amount
    # Material flash works in Compatibility too (instance transparency does not).
    if hit_tween and hit_tween.is_valid(): hit_tween.kill()
    body_mesh.material_override.albedo_color = Color(0.85, 0.28, 0.18)
    hit_tween = create_tween()
    hit_tween.tween_property(body_mesh.material_override, "albedo_color", clothing_color, 0.18)
    if health <= 0:
        alive = false
        collision_layer = 0
        remove_from_group("zombies")
        killed.emit(self)
        var vanish := create_tween()
        vanish.set_parallel(true)
        vanish.tween_property(self, "position:y", position.y - 1.0, 0.5)
        vanish.tween_property(self, "scale", Vector3(0.15, 0.08, 0.15), 0.5)
        vanish.chain().tween_callback(queue_free)
