extends Node2D

@onready var player : CharacterBody2D = $Player
@onready var hud    : CanvasLayer      = $HUD

func _ready() -> void:
	GameManager.start_run()
	hud.link_player(player)
	_add_background()

func _add_background() -> void:
	var bg := ColorRect.new()
	bg.color    = Color(0.06, 0.06, 0.10)
	bg.size     = Vector2(2000, 800)
	bg.position = Vector2(-200, 0)
	bg.z_index  = -10
	add_child(bg)
	move_child(bg, 0)

func _draw() -> void:
	# 바닥
	draw_rect(Rect2(-360, 660, 2000, 40), Color(0.35, 0.35, 0.40))
	# 플랫폼1
	draw_rect(Rect2(210, 520, 280, 20), Color(0.45, 0.45, 0.50))
	# 플랫폼2
	draw_rect(Rect2(650, 420, 200, 20), Color(0.45, 0.45, 0.50))
	# 사다리
	for y in range(430, 525, 20):
		draw_rect(Rect2(476, y, 28, 14), Color(0.55, 0.40, 0.20))
