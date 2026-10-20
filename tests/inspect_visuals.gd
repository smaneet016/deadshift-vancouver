extends SceneTree
## Explicitly staged close-up for inspecting character materials, not a gameplay claim.
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var game = load("res://main.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    game.game_over = true
    game.wave_timer.stop()
    game.player.set_physics_process(false)
    game.player.set_process_unhandled_input(false)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    game._spawn_zombie(0)
    var enemy = get_nodes_in_group("zombies")[0]
    enemy.position = Vector3(-0.8,0.05,3.0)
    enemy.rotation.y = PI
    enemy.set_physics_process(false)
    game.message_label.text = "MODEL REVIEW / STAGED CLOSE-UP"
    await create_timer(3).timeout
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://tests/zombie_visual_review.png")
    print("Saved staged character review")
    quit()
