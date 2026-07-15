extends CharacterBody2D

class_name EnemyBase

const GRAVITY := 900.0

var max_hp   : float = 60.0
var hp       : float = 60.0
var atk      : float = 12.0
var move_spd : float = 80.0
var atk_range : float = 42.0
var atk_cd    : float = 1.2
var exp_reward : int = 15
var gold_reward : int = 10

var _atk_timer   := 0.0
var _player      : CharacterBody2D = null
var _is_dead     := false
var _hit_flash   := 0.0

signal died

func _ready() -> void:
	add_to_group("enemy")
	_player = get_tree().get_first_node_in_group("player")
	_load_cfg()

func _load_cfg() -> void:
	pass  # 서브클래스에서 오버라이드

func _physics_process(delta: float) -> void:
	if _is_dead: return
	_hit_flash = max(0.0, _hit_flash - delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if _player:
		_chase(delta)
		_try_attack(delta)
	move_and_slide()
	queue_redraw()

func _chase(delta: float) -> void:
	var dx := _player.global_position.x - global_position.x
	if abs(dx) > atk_range:
		velocity.x = sign(dx) * move_spd
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_spd * 4 * delta)

func _try_attack(delta: float) -> void:
	_atk_timer -= delta
	if global_position.distance_to(_player.global_position) < atk_range and _atk_timer <= 0.0:
		_atk_timer = atk_cd
		if _player.has_method("take_damage"):
			var kbx: float = GameManager.cfg_f(_cfg_sheet(), "knockback_x", 200.0)
			var kby: float = GameManager.cfg_f(_cfg_sheet(), "knockback_y", -80.0)
			var dir: float = sign(_player.global_position.x - global_position.x)
			_player.take_damage(atk, Vector2(dir * kbx, kby))

func _cfg_sheet() -> String:
	return "BasicEnemy"

func take_damage(amount: float, _knockback: Vector2 = Vector2.ZERO) -> void:
	if _is_dead: return
	hp -= amount
	_hit_flash = 0.12
	if _knockback != Vector2.ZERO:
		velocity = _knockback
	if hp <= 0.0:
		_die()

func _die() -> void:
	_is_dead = true
	GameManager.add_exp(exp_reward)
	GameManager.add_gold(gold_reward)
	GameManager.run_kills += 1
	emit_signal("died")
	queue_free()

func _get_body_color() -> Color:
	return Color(0.75, 0.12, 0.12) if _hit_flash <= 0.0 else Color.WHITE

func _draw_hp_bar() -> void:
	var w := 36.0
	draw_rect(Rect2(-w * 0.5, -_body_height() - 10, w, 5), Color(0.25, 0, 0))
	draw_rect(Rect2(-w * 0.5, -_body_height() - 10, w * (hp / max_hp), 5), Color(0.9, 0.1, 0.1))

func _body_height() -> float:
	return 40.0
