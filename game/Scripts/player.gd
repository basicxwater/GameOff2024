extends CharacterBody3D


# Movement Vars
var current_speed : float = 0.0
@export var walk_speed : float = 7.0
@export var sprint_speed : float = 10.0
@export var crouch_speed : float = 3.0
@export var lerp_speed : float = 10.0

@export var jump_impulse : float = 24.0

@export var mouse_sens : float = 0.05

# State Machine
var state
enum {idle, walking, sprinting, crouching, sliding}

@onready var head = $head
@onready var eyes = $head/eyes

@onready var crouch_collision = $crouching
@onready var standing_collision = $standing

# Dashing
var dash_timer = 0.0
var dash_timer_max = 0.3
var dash_vector = Vector2.ZERO
var dash_speed = 50.0
var dash_count = 1

# Head Bobbing
const head_bob_sprint_speed := 22.0
const head_bob_walk_speed := 14.0
const head_bob_crouch_speed := 10.0

const head_bob_sprint_intensity := 0.2
const head_bob_walk_intensity := 0.1
const head_bob_crouch_intensity := 0.05

var head_bob_vector := Vector2.ZERO
var head_bob_index := 0.0
var head_bob_current_intensity := 0.0
var head_bob_current_speed := 0.0

var crouching_depth := 0.4
var standing_depth := 0.8

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _physics_process(delta: float) -> void:
	match state:
		idle:
			pass
		
		walking:
			current_speed = walk_speed
			crouch_collision.disabled = true
			standing_collision.disabled = false
			head.position.y = lerp(head.position.y, standing_depth, delta * lerp_speed)
			head_bob_current_intensity = head_bob_walk_intensity
			head_bob_current_speed = head_bob_walk_speed
			
		
		sprinting:
			current_speed = sprint_speed
			crouch_collision.disabled = true
			standing_collision.disabled = false
			head.position.y = lerp(head.position.y, standing_depth, delta * lerp_speed)
			head_bob_current_intensity = head_bob_sprint_intensity
			head_bob_current_speed = head_bob_sprint_speed
		
		crouching:
			current_speed = crouch_speed
			crouch_collision.disabled = false
			standing_collision.disabled = true
			head.position.y = lerp(head.position.y, crouching_depth, delta * lerp_speed)
			head_bob_current_intensity = head_bob_crouch_intensity
			head_bob_current_speed = head_bob_crouch_speed
	
	if Input.is_action_pressed("crouch"):
		state = crouching
		
	else:
		if Input.is_action_pressed('sprint'):
			state = sprinting
		else:
			state = walking
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = lerp(velocity.x, direction.x * current_speed, delta * lerp_speed)
		velocity.z = lerp(velocity.z, direction.z * current_speed, delta * lerp_speed)
		
		head_bob_vector.y = sin(head_bob_index)
		head_bob_vector.x = sin(head_bob_index / 2) * 0.5
		
		eyes.position.y = lerp(eyes.position.y, head_bob_vector.y * (head_bob_current_intensity / 2.0), delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, head_bob_vector.x * head_bob_current_intensity, delta * lerp_speed)
		
		head_bob_index += head_bob_current_speed * delta

	else:
		velocity.x = lerp(velocity.x, 0.0, delta * lerp_speed)
		velocity.z = lerp(velocity.z, 0.0, delta * lerp_speed)
	
		eyes.position.y = lerp(eyes.position.y, 0.0, delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta * lerp_speed)
		
		head_bob_current_speed = 0.0
	
		# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = lerp(velocity.y, jump_impulse, delta * lerp_speed)
	
	move_and_slide()
