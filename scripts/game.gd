extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const DOWNTOWN_SCRIPT = preload("res://scripts/downtown.gd")
const ZOMBIE_SCRIPT = preload("res://scripts/zombie.gd")

var player
var level
var wave_pending := false
var wave_timer: Timer
var spawn_timer: Timer
var banner_timer: Timer
var spawn_remaining := 0
var spawn_index := 0
var quality_label: Label
var stats_label: Label
var hud_root: Control
var wave := 0
var zombies_alive := 0
var spawning := false
var game_over := false
var hud: CanvasLayer
var wave_label: Label
var status_label: Label
var health_label: Label
var ammo_label: Label
var gun_label: Label
var message_label: Label
var overlay: ColorRect
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.randomize()
    level = Node3D.new()
    level.set_script(DOWNTOWN_SCRIPT)
    add_child(level)
    player = CharacterBody3D.new()
    player.set_script(PLAYER_SCRIPT)
    player.position = Vector3(0, 0.15, 7)
    player.game = self
    add_child(player)
    player.fired.connect(_on_ammo)
    player.damaged.connect(_on_health)
    player.died.connect(_on_died)
    _build_hud()
    _on_ammo(player.ammo, player.mag_size)
    _on_health(player.health)
    wave_timer = Timer.new()
    wave_timer.one_shot = true
    wave_timer.timeout.connect(_start_wave)
    add_child(wave_timer)
    spawn_timer = Timer.new()
    spawn_timer.wait_time = 0.35
    spawn_timer.timeout.connect(_spawn_tick)
    add_child(spawn_timer)
    banner_timer = Timer.new()
    banner_timer.one_shot = true
    banner_timer.timeout.connect(_hide_banner)
    add_child(banner_timer)
    wave_timer.start(1.5)

func _make_label(parent: Node, words: String, font_size: int, pos: Vector2, color: Color) -> Label:
    var label := Label.new()
    label.text = words
    label.position = pos
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
    label.add_theme_constant_override("shadow_offset_x", 2)
    label.add_theme_constant_override("shadow_offset_y", 2)
    parent.add_child(label)
    return label

func _build_hud() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    hud_root = Control.new()
    hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_root.size = Vector2(1280, 720)
    hud.add_child(hud_root)
    get_viewport().size_changed.connect(_resize_hud)
    _resize_hud()
    var dim := Color(0.64, 0.78, 0.82)
    var bright := Color(0.94, 0.96, 0.96)
    var orange := Color(1.0, 0.43, 0.15)
    wave_label = _make_label(hud_root, "WAVE 01", 24, Vector2(36, 25), bright)
    status_label = _make_label(hud_root, "ZOMBIES LEFT: 0", 14, Vector2(38, 68), orange)
    _make_label(hud_root, "DEADSHIFT // VANCOUVER OUTBREAK", 13, Vector2(38, 104), dim)
    health_label = _make_label(hud_root, "HEALTH 100", 22, Vector2(36, 640), bright)
    ammo_label = _make_label(hud_root, "12 / 12", 28, Vector2(1060, 620), bright)
    gun_label = _make_label(hud_root, "SERVICE CARBINE  ·  LVL 1", 12, Vector2(996, 663), orange)
    message_label = _make_label(hud_root, "HOLD THE FALSE CREEK EVACUATION BLOCK", 22, Vector2(0, 145), bright)
    message_label.size.x = 1280
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    quality_label = _make_label(hud_root, "F3  GRAPHICS: BALANCED", 14, Vector2(1010, 30), dim)
    stats_label = _make_label(hud_root, "", 16, Vector2(0, 184), orange)
    stats_label.size.x = 1280
    stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _make_label(hud_root, "OBJECTIVE: HOLD THE BLOCK • CLEAR WAVES TO UPGRADE", 11, Vector2(38, 126), dim)
    var cross := _make_label(hud_root, "+", 18, Vector2(633, 348), dim)
    cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var tips := _make_label(hud_root, "WASD MOVE   •   SHIFT SPRINT   •   SPACE JUMP   •   LMB FIRE   •   R RELOAD   •   ESC MOUSE", 14, Vector2(270, 690), dim)
    tips.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay = ColorRect.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.color = Color(0.3, 0.0, 0.0, 0.0)
    overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_root.add_child(overlay)

func _start_wave() -> void:
    if game_over:
        return
    wave_pending = false
    stats_label.text = ""
    wave += 1
    wave_label.text = "WAVE %02d" % wave
    var count := 3 + wave * 2
    zombies_alive = count
    status_label.text = "ZOMBIES LEFT: %d" % zombies_alive
    message_label.text = "WAVE %d  •  INCOMING" % wave
    spawning = true
    spawn_remaining = count
    spawn_index = 0
    spawn_timer.start()
    _spawn_tick()

func _spawn_tick() -> void:
    if game_over:
        spawn_timer.stop()
        return
    # Bound simultaneous actors without reducing the escalating wave total.
    if get_tree().get_nodes_in_group("zombies").size() >= 24: return
    _spawn_zombie(spawn_index)
    spawn_index += 1
    spawn_remaining -= 1
    if spawn_remaining == 0:
        spawn_timer.stop()
        spawning = false
        _check_wave_clear()
        banner_timer.start(1.8)

func _hide_banner() -> void:
    if not game_over and not wave_pending:
        message_label.text = ""

func _spawn_zombie(index: int) -> void:
    var zombie = CharacterBody3D.new()
    zombie.set_script(ZOMBIE_SCRIPT)
    zombie.variant = index
    zombie.target = player
    zombie.health = 40.0 + wave * 17.0
    zombie.speed = 2.1 + minf(wave * 0.22, 3.0) + rng.randf_range(-0.25, 0.35)
    zombie.level = level
    zombie.position = level.choose_spawn(player.position, index)
    zombie.killed.connect(_zombie_killed)
    add_child(zombie)

func _zombie_killed(_zombie: CharacterBody3D) -> void:
    zombies_alive -= 1
    status_label.text = "ZOMBIES LEFT: %d" % zombies_alive
    if zombies_alive <= 0 and not spawning and not game_over:
        _wave_cleared()

func _check_wave_clear() -> void:
    if zombies_alive <= 0 and not spawning and not game_over:
        _wave_cleared()

func _wave_cleared() -> void:
    if wave_pending or game_over: return
    wave_pending = true
    var old_damage: float = player.damage
    var old_mag: int = player.mag_size
    var old_delay: float = player.fire_delay
    message_label.text = "WAVE CLEARED  •  WEAPON UPGRADED!"
    player.upgrade()
    stats_label.text = "DAMAGE %d → %d   •   MAG %d → %d   •   RPM %d → %d" % [old_damage, player.damage, old_mag, player.mag_size, 60.0 / old_delay, 60.0 / player.fire_delay]
    player.health = minf(100.0, player.health + 24.0)
    _on_health(player.health)
    gun_label.text = "%s  ·  LVL %d" % [_gun_name(), player.weapon_level]
    wave_timer.start(3.0)

func _gun_name() -> String:
    return "SERVICE CARBINE"

func _on_ammo(remaining: int, capacity: int) -> void:
    if ammo_label:
        ammo_label.text = "%02d / %02d" % [remaining, capacity]
    if gun_label and player:
        gun_label.text = "%s  ·  LVL %d" % [_gun_name(), player.weapon_level]

func _on_health(hp: float) -> void:
    if health_label:
        health_label.text = "HEALTH %03d" % int(hp)
        health_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.25) if hp <= 35 else Color(0.94, 0.96, 0.96))
    if overlay:
        overlay.color.a = (1.0 - hp / 100.0) * 0.12

func _on_died() -> void:
    game_over = true
    wave_timer.stop()
    spawn_timer.stop()
    banner_timer.stop()
    stats_label.text = "SURVIVED TO WAVE %d" % wave
    message_label.text = "YOU DIED  •  PRESS ENTER TO RESTART"

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
        level.set_quality(not level.balanced)
        quality_label.text = "F3  GRAPHICS: " + ("BALANCED" if level.balanced else "LOW")
    if game_over and event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
        get_tree().reload_current_scene()

func _resize_hud() -> void:
    var viewport_size := get_viewport().get_visible_rect().size
    var factor := minf(viewport_size.x / 1280.0, viewport_size.y / 720.0)
    hud_root.scale = Vector2.ONE * factor
    hud_root.position = (viewport_size - Vector2(1280, 720) * factor) / 2.0

func _process(_delta: float) -> void:
    if is_instance_valid(player):
        level.follow_player(player.global_position)
        if player.reload_timer > 0 and not game_over:
            ammo_label.text = "RELOADING"
        elif not game_over:
            ammo_label.text = "%02d / %02d" % [player.ammo, player.mag_size]
