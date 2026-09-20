extends Node3D
@onready var play: Button = $CanvasLayer/Control/Play
@onready var quit: Button = $CanvasLayer/Control/Quit

@export_file("*.tscn") var TARGET_SCENE_PATH: String

func _ready() -> void:
	play.pressed.connect(_on_play_pressed)
	quit.pressed.connect(_on_quit_pressed)
	

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(TARGET_SCENE_PATH)
	
func _on_quit_pressed() -> void:
	get_tree().quit()
