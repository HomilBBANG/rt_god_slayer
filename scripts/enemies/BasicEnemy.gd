extends EnemyBase

func _ready() -> void:
	super._ready()
	max_hp   = 60.0
	hp       = 60.0
	atk      = 12.0
	move_spd = 75.0
	atk_range = 40.0
	atk_cd   = 1.2
	exp_reward  = 15
	gold_reward = 8

func _draw() -> void:
	var col := _get_body_color()
	# 몸통
	draw_rect(Rect2(-14, -40, 28, 40), col)
	# 머리
	draw_circle(Vector2(0, -50), 11, col)
	# 눈 (플레이어 방향)
	if _player:
		var ex: float = 4.0 if _player.global_position.x > global_position.x else -12.0
		draw_rect(Rect2(ex, -54, 8, 6), Color(1, 0.9, 0))
	_draw_hp_bar()
