extends SceneTree
## Short reproducible load sample, not a sustained thermal benchmark.
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var game = load("res://main.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    game.game_over = true # Disable scheduled waves; use exactly 24 live AI actors.
    game.player.health = 100000
    game.player.set_physics_process(false)
    game.player.set_process_unhandled_input(false)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    for i in range(24): game._spawn_zombie(i)
    print("DEVICE: ", RenderingServer.get_video_adapter_name())
    print("VIEWPORT: ", root.size)
    for balanced in [true, false]:
        game.level.set_quality(balanced)
        game.player.rotation = Vector3.ZERO
        var actors := get_nodes_in_group("zombies")
        for i in range(actors.size()):
            actors[i].position = game.level.spawn_points[i % game.level.spawn_points.size()]
            actors[i].repath_timer = 0
            actors[i].anim_time = 0
        await create_timer(2.0).timeout
        var samples: Array[float] = []
        var started := Time.get_ticks_usec()
        var previous := started
        while Time.get_ticks_usec() - started < 8000000:
            await process_frame
            var now := Time.get_ticks_usec()
            samples.append(float(now - previous) / 1000.0)
            previous = now
            # Rotate slowly to sample both storefront rows and the waterfront.
            game.player.rotation.y = sin(float(now - started) / 8000000.0 * TAU) * 0.5
        var elapsed := float(Time.get_ticks_usec() - started) / 1000000.0
        samples.sort()
        print("PROFILE ", "BALANCED" if balanced else "LOW", " | avg FPS ", samples.size() / elapsed, " | p95 frame ms ", samples[int(samples.size() * 0.95)], " | draw calls ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " | static memory MiB ", Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
    game.queue_free()
    await process_frame
    quit()
