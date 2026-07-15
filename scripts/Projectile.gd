extends Area2D

var direction : Vector2 = Vector2.RIGHT
var speed     : float   = 480.0
var damage    : float   = 24.0
var lifetime  : float   = 1.4

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self): queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()

func _draw() -> void:
	var col := Color(0.5, 0.2, 1.0)
	draw_circle(Vector2.ZERO, 7, col)
	draw_circle(Vector2.ZERO, 4, Color(0.8, 0.6, 1.0))
