extends CharacterBody2D

class_name Player

# ── 런타임 설정값 (balance.json에서 로드) ─────────────────
var MOVE_SPEED      : float = 220.0
var CROUCH_MULT     : float = 0.5
var JUMP_VEL        : float = -480.0
var GRAVITY         : float = 900.0
var DASH_SPEED      : float = 650.0
var DASH_DUR        : float = 0.18
var DASH_CD         : float = 0.7
var DASH_SP_COST    : float = 20.0
var SP_REGEN        : float = 22.0
var MP_REGEN        : float = 5.0
var HIT_IFRAMES     : float = 0.5
var KNOCKBACK_FORCE : float = 320.0

# ── 스탯 (balance.json에서 로드) ──────────────────────────
var max_hp      : float = 100.0
var hp          : float = 100.0
var max_sp      : float = 100.0
var sp          : float = 100.0
var max_mp      : float = 80.0
var mp          : float = 80.0
var base_atk    : float = 20.0
var defense     : float = 0.0
var crit_chance : float = 0.08
var crit_mult   : float = 1.8

# ── 상태 ──────────────────────────────────────────────────
var facing_right    := true
var is_crouching    := false
var is_on_ladder    := false
var is_dead         := false

# ── 타이머 ────────────────────────────────────────────────
var iframe_timer    := 0.0
var dash_timer      := 0.0
var dash_cd_timer   := 0.0
var dash_dir        := 1
var drop_timer      := 0.0  # 발판 통과 쿨
var atk_cd          := 0.0
var sp_atk_cd       := 0.0
var magic_cd        := 0.0
var combo_count     := 0
var combo_reset_t   := 0.0

# ── 노드 참조 ─────────────────────────────────────────────
@onready var stand_col  : CollisionShape2D = $StandCol
@onready var crouch_col : CollisionShape2D = $CrouchCol
@onready var atk_area   : Area2D           = $AttackArea
@onready var camera     : Camera2D         = $Camera2D

signal stats_changed(h, mh, s, ms, m, mm)

# ── 초기화 ────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("player")
	atk_area.monitoring = false
	_load_cfg()
	_apply_upgrades()

func _load_cfg() -> void:
	var p := "Player"
	MOVE_SPEED      = GameManager.cfg_f(p, "move_speed",       220.0)
	CROUCH_MULT     = GameManager.cfg_f(p, "crouch_speed_mult", 0.5)
	JUMP_VEL        = GameManager.cfg_f(p, "jump_velocity",   -480.0)
	GRAVITY         = GameManager.cfg_f(p, "gravity",          900.0)
	DASH_SPEED      = GameManager.cfg_f(p, "dash_speed",       650.0)
	DASH_DUR        = GameManager.cfg_f(p, "dash_duration",     0.18)
	DASH_CD         = GameManager.cfg_f(p, "dash_cooldown",     0.7)
	DASH_SP_COST    = GameManager.cfg_f(p, "dash_sp_cost",      20.0)
	SP_REGEN        = GameManager.cfg_f(p, "sp_regen",          22.0)
	MP_REGEN        = GameManager.cfg_f(p, "mp_regen",           5.0)
	HIT_IFRAMES     = GameManager.cfg_f(p, "hit_iframes",        0.5)
	KNOCKBACK_FORCE = GameManager.cfg_f(p, "knockback_force",  320.0)
	max_hp      = GameManager.cfg_f(p, "max_hp",      100.0)
	max_sp      = GameManager.cfg_f(p, "max_sp",      100.0)
	max_mp      = GameManager.cfg_f(p, "max_mp",       80.0)
	base_atk    = GameManager.cfg_f(p, "base_atk",     20.0)
	defense     = GameManager.cfg_f(p, "defense",        0.0)
	crit_chance = GameManager.cfg_f(p, "crit_chance",   0.08)
	crit_mult   = GameManager.cfg_f(p, "crit_mult",     1.8)
	hp = max_hp; sp = max_sp; mp = max_mp

func _apply_upgrades() -> void:
	max_hp  *= 1.0 + GameManager.get_upgrade_bonus("max_hp")
	max_sp  *= 1.0 + GameManager.get_upgrade_bonus("max_sp")
	max_mp  *= 1.0 + GameManager.get_upgrade_bonus("max_mp")
	base_atk *= 1.0 + GameManager.get_upgrade_bonus("atk")
	hp = max_hp; sp = max_sp; mp = max_mp

# ── 메인 루프 ─────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if is_dead: return
	_tick_timers(delta)
	_gravity(delta)
	_ladder(delta)
	_crouch()
	_dash(delta)
	_jump()
	_move()
	_attack()
	move_and_slide()
	_update_crouch_col()
	queue_redraw()

# ── 타이머 ────────────────────────────────────────────────
func _tick_timers(delta: float) -> void:
	iframe_timer  = max(0.0, iframe_timer  - delta)
	dash_timer    = max(0.0, dash_timer    - delta)
	dash_cd_timer = max(0.0, dash_cd_timer - delta)
	drop_timer    = max(0.0, drop_timer    - delta)
	atk_cd        = max(0.0, atk_cd        - delta)
	sp_atk_cd     = max(0.0, sp_atk_cd     - delta)
	magic_cd      = max(0.0, magic_cd      - delta)
	if combo_reset_t > 0.0:
		combo_reset_t -= delta
		if combo_reset_t <= 0.0: combo_count = 0

	sp = min(max_sp, sp + SP_REGEN * delta)
	mp = min(max_mp, mp + MP_REGEN * delta)
	emit_signal("stats_changed", hp, max_hp, sp, max_sp, mp, max_mp)

# ── 중력 ──────────────────────────────────────────────────
func _gravity(delta: float) -> void:
	if is_on_ladder or dash_timer > 0.0: return
	if not is_on_floor():
		velocity.y += GRAVITY * delta

# ── 사다리 ────────────────────────────────────────────────
func _ladder(delta: float) -> void:
	if not is_on_ladder: return
	velocity.y = 0.0
	if Input.is_action_pressed("climb"):
		velocity.y = -MOVE_SPEED * 0.7
	elif Input.is_action_pressed("crouch"):
		velocity.y = MOVE_SPEED * 0.7

# ── 숙이기 ────────────────────────────────────────────────
func _crouch() -> void:
	is_crouching = Input.is_action_pressed("crouch") and is_on_floor() and not is_on_ladder

func _update_crouch_col() -> void:
	stand_col.disabled  = is_crouching
	crouch_col.disabled = not is_crouching

# ── 대시 ──────────────────────────────────────────────────
func _dash(delta: float) -> void:
	if dash_timer > 0.0:
		velocity.x = dash_dir * DASH_SPEED
		velocity.y = 0.0
		return
	if Input.is_action_just_pressed("dash") and dash_cd_timer <= 0.0 and sp >= DASH_SP_COST:
		var ax := Input.get_axis("move_left", "move_right")
		dash_dir = int(sign(ax)) if ax != 0.0 else (1 if facing_right else -1)
		dash_timer    = DASH_DUR
		dash_cd_timer = DASH_CD
		sp -= DASH_SP_COST
		iframe_timer = DASH_DUR + 0.15

# ── 점프 ──────────────────────────────────────────────────
func _jump() -> void:
	if not Input.is_action_just_pressed("jump"): return
	# 사다리에서 점프 → 사다리 이탈
	if is_on_ladder:
		is_on_ladder = false
		velocity.y = JUMP_VEL
		return
	# S + Space → 발판 통과 (one-way layer 4)
	if Input.is_action_pressed("crouch") and is_on_floor():
		set_collision_mask_value(4, false)
		drop_timer = 0.25
		_schedule_platform_restore()
		return
	if is_on_floor():
		velocity.y = JUMP_VEL

func _schedule_platform_restore() -> void:
	await get_tree().create_timer(0.25).timeout
	set_collision_mask_value(4, true)

# ── 이동 ──────────────────────────────────────────────────
func _move() -> void:
	if dash_timer > 0.0: return
	var ax := Input.get_axis("move_left", "move_right")
	var spd: float = MOVE_SPEED * (CROUCH_MULT if is_crouching else 1.0)
	spd *= 1.0 + GameManager.get_upgrade_bonus("spd")
	velocity.x = ax * spd
	if ax != 0.0: facing_right = ax > 0.0

# ── 공격 ──────────────────────────────────────────────────
func _attack() -> void:
	var sp_cost: float = GameManager.cfg_f("Player", "special_sp_cost", 25.0)
	var mp_cost: float = GameManager.cfg_f("Player", "magic_mp_cost",   18.0)
	if Input.is_action_just_pressed("attack") and atk_cd <= 0.0:
		_do_melee()
	if Input.is_action_just_pressed("special") and sp_atk_cd <= 0.0 and sp >= sp_cost:
		_do_special()
	if Input.is_action_just_pressed("magic") and magic_cd <= 0.0 and mp >= mp_cost:
		_do_magic()

func _do_melee() -> void:
	combo_count = (combo_count + 1) % 3
	combo_reset_t = GameManager.cfg_f("Player", "combo_reset_time", 0.6)
	atk_cd        = GameManager.cfg_f("Player", "melee_atk_cd",     0.28)
	var mults := [
		GameManager.cfg_f("Player", "melee_combo1_mult", 1.0),
		GameManager.cfg_f("Player", "melee_combo2_mult", 1.3),
		GameManager.cfg_f("Player", "melee_combo3_mult", 1.6),
	]
	var dmg := _calc_dmg(base_atk * mults[combo_count])
	var rx: float = GameManager.cfg_f("Player", "melee_range_x", 55.0)
	var ry: float = GameManager.cfg_f("Player", "melee_range_y", 28.0)
	_hit_enemies(dmg, rx, ry)

func _do_special() -> void:
	sp        -= GameManager.cfg_f("Player", "special_sp_cost",  25.0)
	sp_atk_cd  = GameManager.cfg_f("Player", "special_atk_cd",   0.85)
	var mult: float = GameManager.cfg_f("Player", "special_atk_mult", 1.7)
	var rx: float   = GameManager.cfg_f("Player", "special_range_x",  85.0)
	var ry: float   = GameManager.cfg_f("Player", "special_range_y",  36.0)
	_hit_enemies(_calc_dmg(base_atk * mult), rx, ry)

func _do_magic() -> void:
	mp       -= GameManager.cfg_f("Player", "magic_mp_cost",   18.0)
	magic_cd  = GameManager.cfg_f("Player", "magic_cd",         0.65)
	var proj_scene := load("res://scenes/Projectile.tscn") as PackedScene
	if not proj_scene: return
	var proj := proj_scene.instantiate()
	proj.direction = Vector2(1.0 if facing_right else -1.0, 0.0)
	proj.speed     = GameManager.cfg_f("Player", "magic_proj_speed", 480.0)
	proj.damage    = _calc_dmg(base_atk * GameManager.cfg_f("Player", "magic_atk_mult", 1.2))
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector2(24.0 * (1.0 if facing_right else -1.0), -28.0)

func _hit_enemies(damage: float, range_x: float, range_y: float) -> void:
	var ox: float = range_x * 0.5 * (1.0 if facing_right else -1.0)
	atk_area.position = Vector2(ox, -28.0)
	var shape := atk_area.get_child(0) as CollisionShape2D
	if shape and shape.shape is RectangleShape2D:
		(shape.shape as RectangleShape2D).size = Vector2(range_x, range_y)
	atk_area.monitoring = true
	var kbx: float = KNOCKBACK_FORCE if facing_right else -KNOCKBACK_FORCE
	for body in get_tree().get_nodes_in_group("enemy"):
		if not body.has_method("take_damage"): continue
		var diff: Vector2 = body.global_position - global_position
		var in_range_x: bool = diff.x > 0.0 if facing_right else diff.x < 0.0
		if in_range_x and abs(diff.x) < range_x and abs(diff.y) < range_y + 20.0:
			body.take_damage(damage, Vector2(kbx, -120.0))
	atk_area.monitoring = false

func _calc_dmg(base: float) -> float:
	var c := crit_chance + GameManager.get_upgrade_bonus("crit")
	return base * (crit_mult if randf() < c else 1.0)

# ── 피격 ──────────────────────────────────────────────────
func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> void:
	if iframe_timer > 0.0 or is_dead: return
	var actual: float = maxf(1.0, amount - defense)
	hp -= actual
	iframe_timer = HIT_IFRAMES
	if knockback != Vector2.ZERO:
		velocity = knockback
	if hp <= 0.0:
		hp = 0.0
		_die()
	emit_signal("stats_changed", hp, max_hp, sp, max_sp, mp, max_mp)

func _die() -> void:
	is_dead = true
	GameManager.on_player_died()
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

# ── 사다리 연결 ───────────────────────────────────────────
func enter_ladder() -> void:
	is_on_ladder = true
	velocity.y   = 0.0

func exit_ladder() -> void:
	is_on_ladder = false

# ── 시각 (placeholder) ────────────────────────────────────
func _draw() -> void:
	var alpha: float = 0.35 if iframe_timer > 0.0 and fmod(iframe_timer, 0.1) < 0.05 else 1.0
	var col := Color(0.18, 0.42, 0.90, alpha)

	if is_crouching:
		draw_rect(Rect2(-14, -28, 28, 28), col)
	else:
		draw_rect(Rect2(-14, -56, 28, 56), col)
		# 머리
		draw_circle(Vector2(0, -64), 12, col)

	# 방향 표시 눈
	var eye_x: float = 6.0 if facing_right else -14.0
	var eye_y: float = -62.0 if not is_crouching else -22.0
	draw_rect(Rect2(eye_x, eye_y, 8, 7), Color.WHITE)

	# 대시 중 잔상
	if dash_timer > 0.0:
		draw_rect(Rect2(-14 + (dash_dir * -20), -56, 28, 56), Color(0.5, 0.7, 1.0, 0.3))
