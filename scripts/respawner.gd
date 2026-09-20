extends Node3D

@export var enemy1 : PackedScene
@export var enemy2 : PackedScene

var spawn_count:= 1
func _ready() -> void:
	var diff_timer = Timer.new()
	diff_timer.wait_time = 20.0
	diff_timer.autostart = true
	diff_timer.timeout.connect(_on_difficulty_timeout())
	add_child(diff_timer)
	
func _on_difficulty_timeout():
	spawn_count += 1
func _on_timer_timeout() -> void:
	for i in range(spawn_count):
		var instance = enemy1.instantiate()
		var instance2 = enemy2.instantiate()
		add_child(instance)
		add_child(instance2)
	
