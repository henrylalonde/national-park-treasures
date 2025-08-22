class_name Player extends CharacterBody2D

const SPEED_RAMP = [-180.0, -160.0, -140.0, -80.0, -20.0, -10.0, 0.0, 10.0, 20.0, 80.0, 140.0, 160.0, 180.0]
const SPEED_ZERO = 6
const SPEED_MAX = 12

const MAX_JUMP_TIME = 0.25
const JUMP_VELOCITY = -100.0
const JUMP_FORCE = -500.0

@onready var tail = $Tail
@onready var animation_player = $AnimationPlayer

var speed_index = 7
var jump_time := 0.0

# because I'm nice and I want the game to feel good
var floor_frames = [true, true, true]
var ff_i := 0
var jump_frames = [false, false, false]
var jf_i := 0

var move_direction := Vector2(0.0, 0.0)
var is_facing_right := true

var current_state := "idle_right"
var next_state := ""
var fsm: Dictionary[String, Callable] = {
	"idle_right": _idle_right,
	"idle_left": _idle_left,
	"run_right": _run_right,
	"run_left": _run_left,
	"turn_right_to_left": _turn_right_to_left,
	"turn_left_to_right": _turn_left_to_right,
	"jump_right": _jump_right,
	"jump_left": _jump_left,
	"fall_right": _fall_right,
	"fall_left": _fall_left
}
	

func _physics_process(delta: float) -> void:
	# update floor and jump buffer indices
	ff_i = (ff_i + 1) % 3
	jf_i = (jf_i + 1) % 3
	
	if Input.is_action_just_pressed("jump"):
		jump_frames[jf_i] = true
	else:
		jump_frames[jf_i] = false
		
	if not is_on_floor():
		floor_frames[ff_i] = false
		velocity += get_gravity() * delta
		if Input.is_action_pressed("jump") and jump_time < MAX_JUMP_TIME:
			velocity.y += JUMP_FORCE * delta
			jump_time += delta
		if jump_frames.any(func(e): return e) and floor_frames.any(func(e): return e):
			velocity.y = JUMP_VELOCITY
			jump_time = 0.0
	else: 
		floor_frames[ff_i] = true
		if jump_frames.any(func(e): return e):
			velocity.y = JUMP_VELOCITY
			jump_time = 0.0
	
	# Get the input direction and handle the movement/deceleration.
	move_direction.x = round(Input.get_axis("move_left", "move_right"))
	move_direction.y = round(Input.get_axis("move_up", "move_down"))
	if move_direction.x == 0.0:
		speed_index += sign(SPEED_ZERO - speed_index)
	else:
		speed_index = clamp(speed_index + move_direction.x, 0, SPEED_MAX)
	velocity.x = SPEED_RAMP[speed_index]
	
	move_and_slide()
	update_animation()
	

# This is where stuff gets crazy with the animation state machine
func update_animation() -> void:
	fsm[current_state].call()
	

func _idle_right() -> void:
	if move_direction.x > 0.0:
		current_state = "run_right"
	elif move_direction.x < 0.0:
		current_state = "turn_right_to_left"
	elif not is_on_floor():
		if velocity.y < 0.0:
			current_state = "jump_right"
		elif velocity.y > 0.0:
			current_state = "fall_right"
	animation_player.play("idle_right")
	

func _idle_left() -> void:
	if move_direction.x > 0.0:
		current_state = "turn_left_to_right"
	elif move_direction.x < 0.0:
		current_state = "run_left"
	if not is_on_floor():
		if velocity.y < 0.0:
			current_state = "jump_left"
		elif velocity.y > 0.0:
			current_state = "fall_left"
	animation_player.play("idle_left")
	

func _run_right() -> void:
	if move_direction.x <= 0.0:
		current_state = "idle_right"
	elif not is_on_floor():
		if velocity.y < 0.0:
			current_state = "jump_right"
		elif velocity.y > 0.0:
			current_state = "fall_right"
	animation_player.play("run_right")
	

func _run_left() -> void:
	if move_direction.x >= 0.0:
		current_state = "idle_left"
	if not is_on_floor():
		if velocity.y < 0.0:
			current_state = "jump_left"
		elif velocity.y > 0.0:
			current_state = "fall_left"
	animation_player.play("run_left")

func _turn_right_to_left() -> void:
	if animation_player.assigned_animation != "turn_right_to_left":
		next_state = "run_left"
		animation_player.play("turn_right_to_left")
	

func _turn_left_to_right() -> void:
	if animation_player.assigned_animation != "turn_left_to_right":
		next_state = "run_right"
		animation_player.play("turn_left_to_right")
		

func _jump_right() -> void:
	if is_on_floor():
		current_state = "run_right"
	elif velocity.y >= 0.0:
		current_state = "fall_right"
	elif velocity.x < 0.0:
		current_state = "jump_left"
	elif animation_player.assigned_animation != "jump_right":
		animation_player.play("jump_right")


func _jump_left() -> void:
	if is_on_floor():
		current_state = "run_left"
	elif velocity.y >= 0.0:
		current_state = "fall_left"
	elif velocity.x > 0.0:
		current_state = "jump_right"
	elif animation_player.assigned_animation != "jump_left":
		animation_player.play("jump_left")
	

func _fall_right() -> void:
	if velocity.y <= 0.0 or is_on_floor():
		current_state = "run_right"
	elif move_direction.x < 0.0:
		current_state = "fall_left"
	elif animation_player.assigned_animation != "fall_right":
		animation_player.play("fall_right")
	

func _fall_left() -> void:
	if velocity.y <= 0.0 or is_on_floor():
		current_state = "run_left"
	elif move_direction.x > 0.0:
		current_state = "fall_right"
	elif animation_player.assigned_animation != "fall_left":
		animation_player.play("fall_left")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if next_state != "":
		current_state = next_state
		next_state = ""
