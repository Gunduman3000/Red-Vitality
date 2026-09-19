extends Node

var tomatoes_killed : int = 0

@onready var label : Label  = $Control/Label

var paused : bool = false

@onready var resume_button : Button = $Control/PAUSEMENU/Resume
@onready var main_menu_button : Button = $Control/PAUSEMENU/Main_Menu
@onready var pause_menu : Node = $Control/PAUSEMENU

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	$Control/PAUSEMENU.visible = false
	
func _on_node_added(node: Node) -> void:
	if node is mob:
		node.die.connect(_on_enemy_killed)


func _on_enemy_killed() -> void:
	tomatoes_killed += 1
	label.text = str(tomatoes_killed)
	
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Pause") and not paused:
		_on_enter_paused()
	elif Input.is_action_just_pressed('Pause') and paused:
		_on_exit_paused()
	
	if resume_button.pressed:
		_on_exit_paused()
	
	if main_menu_button.pressed:
		pass
		
func _on_enter_paused() -> void:
	paused = true
	Engine.time_scale = 0
	pause_menu.visible = true
	
	
func _on_exit_paused() -> void:
	paused = false
	Engine.time_scale = 1
	pause_menu.visible = false
	


	
