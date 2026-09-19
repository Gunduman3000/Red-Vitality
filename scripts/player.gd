extends CharacterBody3D

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sens:=0.25

@export_group("Movement")
@export var move_speed:= 70
@export var acceleration:= 300
@export var rotation_speed:= 2
@export var jump_impulse:= 12.0

var camera_input_direction:= Vector2.ZERO
var last_movement_direction:= Vector3.BACK

@onready var camera_pivot: Node3D = %CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera

"""func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED 
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE"""

func _unhandled_input(event: InputEvent) -> void:
	var is_camera_movement:=(
		event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_movement:
		camera_input_direction = event.relative * mouse_sens

func _physics_process(delta: float) -> void: 
	
	camera_pivot.rotation.x += camera_input_direction.y * delta
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI/6.0, PI/3.0)
	camera_pivot.rotation.y -= camera_input_direction.x * delta
	camera_input_direction = Vector2.ZERO

	var raw_input:= Input.get_vector("move_left", "move_right","move_front", "move_back")
	var forward := camera.global_basis.z
	var right := camera.global_basis.x
	
	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized() 
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():         
		velocity.y = jump_impulse
	var target_velocity_x := move_direction.x * move_speed
	var target_velocity_z := move_direction.z * move_speed
	
	velocity.x = move_toward(velocity.x, target_velocity_x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity_z, acceleration * delta)
	move_and_slide()
	
	if move_direction.length()> 0.2:
		last_movement_direction = move_direction
	var _target_angle := Vector3.BACK.signed_angle_to(last_movement_direction, Vector3.UP)
	rotation.y = lerp_angle(rotation.y, _target_angle, rotation_speed * delta)
	
