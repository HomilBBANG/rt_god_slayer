extends Area2D

func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _on_enter(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("enter_ladder"):
		body.enter_ladder()

func _on_exit(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("exit_ladder"):
		body.exit_ladder()
