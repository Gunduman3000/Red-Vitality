extends CharacterBody3D
class_name mob
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
enum States {attack, chase}
var state = States.chase
@export var hp := 10
@export var SPEED := 50
@export var acceleration := 90
var target = null
signal killed
func _ready():
	target = get_tree().get_first_node_in_group("player")
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if state == States.attack:
		velocity = Vector3.ZERO
		print("attack")
	elif state == States.chase:
		if target != null:
			navigation_agent_3d.target_position = target.global_position
			if navigation_agent_3d.is_navigation_finished():
				velocity.x = 0
				velocity.z = 0
			else:
				var next_pos = navigation_agent_3d.get_next_path_position()
				var direction = global_position.direction_to(next_pos)
				direction.y = 0.0
				direction = direction.normalized()
				velocity.x = lerp(velocity.x, direction.x * SPEED, acceleration * delta)
				velocity.z = lerp(velocity.z, direction.z * SPEED, acceleration * delta)
	move_and_slide()
func die() -> void:
	killed.emit()
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method("player"):
		state = States.attack
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.has_method("player"):
		state = States.chase
