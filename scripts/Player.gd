extends CharacterBody2D

# 벨트스크롤: 좌우 이동 / 숙이기 / 사다리
const SPEED := 220.0
const GRAVITY := 980.0

var is_crouching := false
var is_on_ladder := false


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_movement()
	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if is_on_ladder:
		velocity.y = 0.0
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta


func _handle_movement() -> void:
	# S — 숙이기 (바닥에 있을 때만)
	is_crouching = Input.is_action_pressed("crouch") and is_on_floor()

	# W — 사다리 타기 (사다리 Area2D에서 is_on_ladder = true 처리)
	if is_on_ladder:
		velocity.y = -SPEED if Input.is_action_pressed("climb") else 0.0

	# A / D — 좌우 이동 (숙인 중 절반 속도)
	var speed := SPEED * (0.5 if is_crouching else 1.0)
	var dir := Input.get_axis("move_left", "move_right")
	velocity.x = dir * speed
