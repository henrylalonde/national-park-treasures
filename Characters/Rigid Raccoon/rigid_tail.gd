extends Line2D

@export var tail_root := Vector2(-3.0, 1.0)

@onready var raccoon: RigidBody2D = get_parent()
@onready var body: Sprite2D = get_parent().get_node("Body")

const SEGMENT_LENGTH := 1.5
const DAMPING := 12.0
const DIRECTIONAL_FORCE := 30.0
const WAVE_FORCE := 40.0
const DROOP_FORCE := 2.0
const WIND_FORCE := 30.0
const POINT_COUNT := 8

var tail_velocities := []

func _ready() -> void:
	for i in range(POINT_COUNT):
		tail_velocities.append(Vector2(0.0, 0.0))
	
	
func _physics_process(delta: float) -> void:
	points[0] = tail_root
	
	for i in range(1, POINT_COUNT):
		var old_position = points[i]
		var 	force = -DAMPING * tail_velocities[i]

		if raccoon.linear_velocity.x == 0.0 and raccoon.linear_velocity.y == 0.0:
			var idle_wave = sin(PI * (0.125 * i + 0.0024 * Time.get_ticks_msec()))
			force += WAVE_FORCE * Vector2.UP * idle_wave
			force += DROOP_FORCE * Vector2.DOWN * i
		else:
			force += -WIND_FORCE * raccoon.linear_velocity
		
		if body.flip_h == false:
			var desired_loc = tail_root.x - i * SEGMENT_LENGTH - points[i].x
			force.x += desired_loc * desired_loc * desired_loc * DIRECTIONAL_FORCE
		else:
			var desired_loc = tail_root.x + i * SEGMENT_LENGTH - points[i].x
			force.x += desired_loc * desired_loc * desired_loc * DIRECTIONAL_FORCE
		
		tail_velocities[i] += force * delta
		var temp = points[i]
		temp += tail_velocities[i] * delta
		var dist = temp - points[i - 1]
		points[i] = points[i - 1] + SEGMENT_LENGTH * dist.normalized()
		tail_velocities[i] = (points[i] - old_position) / delta
