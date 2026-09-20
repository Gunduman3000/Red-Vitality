extends CharacterBody3D
class_name Mob

enum States {attack, chase, die}

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

@export var hp := 10
@export var SPEED := 5.0 

var state = States.chase
var target = null

signal killed

func _ready() -> void:
	await get_tree().physics_frame
	target = get_tree().get_first_node_in_group("player")
	
	print("TARGET NODE NAME: ", target.name if target else "NULL")
	print("TARGET INITIAL POS: ", target.global_position if target else "NULL")

func _physics_process(delta: float) -> void:
	if hp <= 0:
		state = States.die
	if not is_on_floor():
		velocity += get_gravity() * delta

	if state == States.attack:
		velocity.x = 0.0
		velocity.z = 0.0
		print("attack")
		
	elif state == States.chase:
		if target != null:
			navigation_agent_3d.target_position = target.global_position
			
			if navigation_agent_3d.is_navigation_finished():
				velocity.x = 0.0
				velocity.z = 0.0
			else:
				var next_pos = navigation_agent_3d.get_next_path_position() 
				var direction = global_position.direction_to(next_pos)
				print(next_pos)
				direction.y = 0.0
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			print('target null')
	elif state == States.die:
			killed.emit()
			queue_free()
	move_and_slide()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method("player"):
		state = States.attack

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.has_method("player"):
		state = States.chase
