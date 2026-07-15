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

