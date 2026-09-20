extends CharacterBody3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_cool_down: Timer = $"attack cool down"

@export_group("Movement")
@export var move_speed:= 70.0
@export var acceleration:= 300.0
@export var rotation_speed:= 3.0 #
@export var rotation_acceleration:= 12.0 
@export var jump_impulse:= 35.0
@export var maxhp:= 100
var hp:= maxhp
@export var damage := 10
var target = []
var camera_input_direction:= Vector2.ZERO
var last_movement_direction:= Vector3.BACK
var onCooldown = false

var current_turn_speed:= 0.0

@onready var hpbar: TextureProgressBar = $"../HUD/HUD/HPBAR" if has_node("../HUD/HPBAR") else null
@onready var camera_pivot: Node3D = %CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera

func _ready() -> void:
	if hpbar:
		hpbar.max_value = maxhp

func _physics_process(delta: float) -> void: 
	if hpbar:
		hpbar.value = hp
	
	rotation.x = 0.0
	rotation.z = 0.0

	var turn_input := Input.get_axis("move_right", "move_left")
	var target_turn_speed := turn_input * rotation_speed
	current_turn_speed = move_toward(current_turn_speed, target_turn_speed, rotation_acceleration * delta)
	
	rotate_y(current_turn_speed * delta)

	var forward_input := Input.get_axis("move_back", "move_front")
	var move_direction := global_transform.basis.z
	move_direction.y = 0.0
	move_direction = move_direction.normalized() * forward_input

	if not is_on_floor():
		velocity.y += get_gravity().y * 10 * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():          
		velocity.y = jump_impulse

	var target_velocity := move_direction * move_speed
	var current_horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	var new_horizontal_velocity := current_horizontal_velocity.move_toward(target_velocity, acceleration * delta)

	velocity.x = new_horizontal_velocity.x
	velocity.z = new_horizontal_velocity.z

	move_and_slide()
	attack()
func attack():
	if Input.is_action_just_pressed("left_click") and onCooldown == false:
		animation_player.play("attack_swing")
		onCooldown = true
		attack_cool_down.start()
func player():
	pass
func deal_dmg():
	for enemies in target:
		enemies.hp -= damage
func _on_attack_area_body_entered(body: Node3D) -> void:
	if body.has_method("enemy"):
		target.appendd(body)
func _on_attack_area_body_exited(body: Node3D) -> void:
	if body.has_method("enemy"):
		target.erase(body)

func _on_attack_cool_down_timeout() -> void:
	onCooldown = false
