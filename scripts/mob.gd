extends CharacterBody3D
class_name mob
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
 
const SPEED = 5

func _ready() -> void:
	target_position(Vector3(0,0,-10))
	
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	var target_pos = navigation_agent_3d.get_next_path_position()
	var current_pos = global_transform.origin
	var new_velocity = (target_pos - current_pos).normalized() * SPEED
	velocity = velocity.move_toward(new_velocity,0.25)
	move_and_slide()
func target_position(target_p):
	navigation_agent_3d.target_position = target_p

	
	
