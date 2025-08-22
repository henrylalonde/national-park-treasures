extends RigidBody2D

@onready var animation_player = $AnimationPlayer

var move_direction = Vector2(0.0, 0.0)

func _ready() -> void:
	lock_rotation = true


func _physics_process(delta: float) -> void:
	move_direction.x = round(Input.get_axis("move_left", "move_right"))
	move_direction.y = round(Input.get_axis("move_up", "move_down"))
	apply_central_force(1000.0 * move_direction)
