extends Node

var tomatoes_killed : int = 0
var paused : bool = false

@onready var pause_menu_ui : Control = $CanvasLayer/Control
@onready var label : Label = $CanvasLayer/Control/Label
@onready var resume_button : Button = $CanvasLayer/Control/Resume
@onready var main_menu_button : Button = $CanvasLayer/Control/Main_Menu

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	
	resume_button.pressed.connect(_on_resume_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	
	
	resume_button.visible = false
	main_menu_button.visible = false
	label.visible = true 

func _on_node_added(node: Node) -> void:
	if node is mob:
		node.die.connect(_on_enemy_killed)

func _on_enemy_killed() -> void:
	tomatoes_killed += 1
	label.text = str(tomatoes_killed)
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Pause"):
		if not paused:
			_on_enter_paused()
		else:
			_on_exit_paused()

func _on_enter_paused() -> void:
	paused = true
	Engine.time_scale = 0
	
	pause_menu_ui.visible = true
	resume_button.visible = true
	main_menu_button.visible = true
	
func _on_exit_paused() -> void:
	paused = false
	Engine.time_scale = 1
	
	resume_button.visible = false
	main_menu_button.visible = false

func _on_resume_pressed() -> void:
	_on_exit_paused()

func _on_main_menu_pressed() -> void:
	pass
