extends SceneTree
## Run: Godot --headless --path . --script res://tests/smoke.gd
var failures := 0
var checks := 0
var game
func _initialize() -> void:
    auto_accept_quit = false
    call_deferred("run")
func check(ok: bool, description: String) -> void:
    checks += 1
    if not ok: failures += 1
    print(("PASS: " if ok else "FAIL: ") + description)
func frames(count: int) -> void:
    for i in range(count): await physics_frame
func run() -> void:
    game = load("res://main.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    await frames(15)
    var p = game.player
    check(p.is_on_floor(), "player lands on downtown pavement")
    check(p.health == 100 and p.ammo == 12, "original starting health and ammo")
    for spawn in game.level.spawn_points:
        var cell := Vector2i(roundi(spawn.x), roundi(spawn.z))
        check(not game.level.grid.is_point_solid(cell), "spawn is clear: %s" % spawn)
        check(game.level.route(spawn, p.position).size() > 1, "spawn reaches initial player: %s" % spawn)
    var navigable := 0
    var disconnected := 0
    for x in range(-31, 32):
        for z in range(-31, 32):
            if not game.level.grid.is_point_solid(Vector2i(x, z)):
                navigable += 1
                if game.level.route(Vector3(x, 0, z), p.position).is_empty(): disconnected += 1
    check(disconnected == 0, "all %d walkable grid cells connect to arena" % navigable)
    game.level.set_quality(false)
    check(game.level.rain.amount == 160 and not game.level.moon.shadow_enabled, "low graphics budget")
    game.level.set_quality(true)
    check(game.level.rain.amount == 420 and game.level.moon.shadow_enabled, "balanced graphics budget")
    # Mouse input handling and normalized movement velocity remain intact.
    var motion := InputEventMouseMotion.new()
    motion.relative = Vector2(20, 10)
    p._unhandled_input(motion)
    if DisplayServer.get_name() != "headless":
        check(absf(p.rotation.y) > 0.01 and absf(p.camera.rotation.x) > 0.01, "mouse look rotates player and camera")
    else:
        print("SKIP: captured mouse look requires a display; covered in rendered test")
    # Prevent physical mouse clicks outside this test from firing during assertions.
    p.set_process_unhandled_input(false)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    p.rotation = Vector3.ZERO
    p.camera.rotation = Vector3.ZERO
    var move := InputEventKey.new()
    move.keycode = KEY_W
    move.pressed = true
    Input.parse_input_event(move)
    await frames(15)
    check(p.velocity.z < -6.5, "W walks forward")
    var sprint := InputEventKey.new()
    sprint.keycode = KEY_SHIFT
    sprint.pressed = true
    Input.parse_input_event(sprint)
    await frames(3)
    check(p.velocity.length() > 10, "Shift sprints")
    move.pressed = false
    sprint.pressed = false
    Input.parse_input_event(move)
    Input.parse_input_event(sprint)
    var jump := InputEventKey.new()
    jump.keycode = KEY_SPACE
    jump.pressed = true
    Input.parse_input_event(jump)
    await frames(3)
    check(p.velocity.y > 0, "Space jumps from pavement")
    jump.pressed = false
    Input.parse_input_event(jump)
    await frames(50)
    check(p.is_on_floor(), "jump lands back on solid pavement")
    # Wait for the genuine timed first wave rather than manually creating it.
    while game.spawning or game.wave == 0: await frames(1)
    check(game.wave == 1 and game.zombies_alive == 5, "wave one spawns five enemies")
    var zombie = get_nodes_in_group("zombies")[0]
    for other in get_nodes_in_group("zombies"): other.set_physics_process(false)
    p.position = Vector3(0, 0.05, 7)
    p.rotation = Vector3.ZERO
    zombie.position = Vector3(0, 0.05, 2)
    await frames(3)
    var before: float = zombie.health
    p.shoot()
    check(zombie.health == before - 30 and p.ammo == 11, "real hitscan damages zombie and spends exactly one round")
    p.shoot()
    check(p.ammo == 11, "fire cooldown prevents duplicate shot")
    p.reload()
    p.shoot()
    check(p.ammo == 11, "cannot shoot during reload")
    await create_timer(1.35).timeout
    check(p.ammo == 12, "timed reload refills magazine")
    # Attack through cover must fail; direct contact still damages.
    zombie.position = Vector3(6, 0.05, -7.65)
    p.position = Vector3(6, 0.05, -6.35)
    zombie.attack_cooldown = 0
    await frames(3)
    zombie._physics_process(0.016)
    check(p.health == 100, "barrier blocks melee attack")
    zombie.position = Vector3(0, 0.05, 6)
    p.position = Vector3(0, 0.05, 7)
    zombie.attack_cooldown = 0
    await frames(3)
    zombie._physics_process(0.016)
    check(p.health == 89, "unobstructed zombie contact damages player")
    zombie._physics_process(0.016)
    check(p.health == 89, "zombie attack cooldown retained")
    # Physically follow an A* route around the parked bus.
    p.position = Vector3(-8.6, 0.05, 10)
    zombie.position = Vector3(-8.6, 0.05, -7)
    zombie.speed = 5
    zombie.repath_timer = 0
    zombie.set_physics_process(true)
    var reached := false
    for i in range(480):
        await physics_frame
        if zombie.position.distance_to(p.position) < 1.5:
            reached = true
            break
    zombie.set_physics_process(false)
    check(reached, "zombie physically routes around bus to player")
    for enemy in get_nodes_in_group("zombies"): enemy.take_hit(10000, enemy.global_position)
    await frames(2)
    check(game.zombies_alive == 0 and game.wave_pending, "last enemy clears wave exactly once")
    check(p.weapon_level == 2 and p.damage == 40 and p.mag_size == 17 and is_equal_approx(p.fire_delay, 0.2772), "automatic upgrade preserves damage, magazine and fire rate math")
    check(p.ammo == 17 and p.gun.scale.x > 1, "upgrade reloads and visibly scales original gun")
    check(game.stats_label.text.contains("30 → 40"), "upgrade HUD displays actual stat change")
    game._check_wave_clear()
    check(p.weapon_level == 2, "duplicate clear check cannot grant extra upgrade")
    await create_timer(3.1).timeout
    check(game.wave == 2 and game.zombies_alive == 7, "wave two automatically starts with seven enemies")
    p.take_damage(1000)
    check(game.game_over and p.dead and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "death releases mouse and ends gameplay")
    var ammo_before: int = p.ammo
    p.shoot()
    check(p.ammo == ammo_before, "dead player cannot fire")
    var enter := InputEventKey.new()
    enter.pressed = true
    enter.keycode = KEY_ENTER
    game._unhandled_input(enter)
    await frames(5)
    check(current_scene != game and current_scene.player.health == 100 and current_scene.player.weapon_level == 1, "Enter reloads level and resets player state")
    # Drive a large wave's real spawn callback to verify its concurrency budget.
    game = current_scene
    game.wave_timer.stop()
    game.wave = 11
    game._start_wave()
    game.spawn_timer.stop()
    for i in range(30): game._spawn_tick()
    check(get_nodes_in_group("zombies").size() == 24 and game.spawn_remaining == 3 and game.zombies_alive == 27, "wave 12 caps live actors at 24 and preserves all 27 enemies")
    get_nodes_in_group("zombies")[0].take_hit(10000, Vector3.ZERO)
    game._spawn_tick()
    check(get_nodes_in_group("zombies").size() == 24 and game.spawn_remaining == 2, "queued enemy spawns when an active slot opens")
    for enemy in get_nodes_in_group("zombies"): enemy.take_hit(10000, Vector3.ZERO)
    check(not game.wave_pending and game.zombies_alive == 2, "queued enemies prevent premature wave completion")
    game._spawn_tick()
    game._spawn_tick()
    for enemy in get_nodes_in_group("zombies"): enemy.take_hit(10000, Vector3.ZERO)
    check(game.wave_pending and game.player.weapon_level == 2, "large wave completes and upgrades after every queued enemy dies")
    await create_timer(0.6).timeout
    print("RESULT: %d checks, %d failures" % [checks, failures])
    quit(1 if failures else 0)
