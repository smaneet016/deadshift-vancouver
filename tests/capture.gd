extends SceneTree
## Rendered smoke test. Requires a display; saves a real in-engine frame.
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var game = load("res://main.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    game.player.set_physics_process(false)
    game.player.set_process_unhandled_input(false)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    game.player.camera.rotation.x = 0.04
    await create_timer(6.0).timeout
    for i in range(5): await process_frame
    await RenderingServer.frame_post_draw
    var target := "res://tests/downtown_preview.png"
    root.get_texture().get_image().save_png(target)
    print("Rendered preview saved: ", target)
    print("Renderer: ", RenderingServer.get_video_adapter_name())
    print("Draw calls: ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
    print("FPS sample (not a benchmark): ", Performance.get_monitor(Performance.TIME_FPS))
    await create_timer(6.0).timeout
    game.player.shoot()
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://tests/combat_preview.png")
    print("Saved live wave combat preview")
    quit()
