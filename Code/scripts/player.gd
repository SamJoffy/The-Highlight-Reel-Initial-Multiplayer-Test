class_name Player

extends CharacterBody3D



@export var JUMP_VELOCITY: float = 6.0
@export var SPEED: float = 10.0
@export var MOUSE_SENSITIVITY : float = 1.0
@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER : Camera3D
@export var RAYCAST : RayCast3D
@export var PLAYERMODEL : Node3D

@onready var LEFTRAYCAST: RayCast3D = %LeftRayCast
@onready var RIGHTRAYCAST: RayCast3D = %RightRayCast
@onready var crosshair: MeshInstance3D = $CameraController/Camera3D/MeshInstance3D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var _mouse_input: bool = false
var _mouse_rotation : Vector3
var _rotation_input: float = 0.0
var _player_rotation : Vector3
var _camera_rotation : Vector3
var _current_rotation : float
var _tilt_input: float = 0.0
var jump_ready: bool = true
var isFocused: bool = true
var health: int = 3

signal healthChanged(healthValue: int)

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	CAMERA_CONTROLLER.current = is_multiplayer_authority()
	if is_multiplayer_authority():
		for i in PLAYERMODEL.get_children():
			i.set_layer_mask_value(3, false)
		set_collision_layer_value(3, false)
		crosshair.visible = true

func _physics_process(delta):
	_update_camera(delta)

func _notification(what):
	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			isFocused = false
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			isFocused = true

func _input(event):
	if is_multiplayer_authority():
		if event.is_action_pressed("exit"):
			get_tree().quit()
		elif event.is_action_pressed("shoot"):
			if RAYCAST.is_colliding():
				RAYCAST.get_collider().hitPlayer.rpc_id(RAYCAST.get_collider().get_multiplayer_authority())

func _unhandled_input(event):
	if is_multiplayer_authority():
		_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
		if _mouse_input:
			_rotation_input = -event.relative.x * MOUSE_SENSITIVITY
			_tilt_input = -event.relative.y * MOUSE_SENSITIVITY

func _update_camera(delta):
	if isFocused and is_multiplayer_authority():
		_current_rotation = _rotation_input
		_mouse_rotation.x += _tilt_input * delta
		_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
		_mouse_rotation.y += _rotation_input * delta
		
		_player_rotation = Vector3(0.0, _mouse_rotation.y, 0.0)
		_camera_rotation = Vector3(_mouse_rotation.x, 0.0, 0.0)
		
		CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
		CAMERA_CONTROLLER.rotation.z = 0.0
		
		global_transform.basis = Basis.from_euler(_player_rotation)
		
		_rotation_input = 0.0
		_tilt_input = 0.0

func update_gravity(delta, isWallRunning: bool = false) -> void:
	if not isWallRunning:
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

func update_input(speed: float, acceleration: float, deceleration: float, isWallRunning: bool = false) -> void:
	if is_multiplayer_authority():
		var input_dir = Input.get_vector("left", "right", "forwards", "backwards")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = lerp(velocity.x, direction.x * speed, acceleration)
			velocity.z = lerp(velocity.z, direction.z * speed, acceleration)
		else:
			velocity.x = move_toward(velocity.x, 0, deceleration)
			velocity.z = move_toward(velocity.z, 0, deceleration)
		
		# Handle jump.
		if Input.is_action_just_pressed("jump") and jump_ready and not isWallRunning:
			jump_ready = false
			velocity.y = JUMP_VELOCITY
			await get_tree().create_timer(0.2).timeout
			jump_ready = true
		elif Input.is_action_just_pressed("jump") and isWallRunning:
			var forwardDirection = Vector3(1, 0, 1)
			if LEFTRAYCAST.is_colliding():
				velocity = LEFTRAYCAST.get_collision_normal() * JUMP_VELOCITY * 10
				forwardDirection -= LEFTRAYCAST.get_collision_normal()
			elif RIGHTRAYCAST.is_colliding():
				velocity = RIGHTRAYCAST.get_collision_normal() * JUMP_VELOCITY * 10
				forwardDirection -= RIGHTRAYCAST.get_collision_normal()
			var forwardVelocity = forwardDirection * speed
			velocity += forwardVelocity

func update_velocity() -> void:
	if is_multiplayer_authority():
		move_and_slide()

@rpc("any_peer")
func hitPlayer():
	health -= 1
	if health <= 0:
		self.position = Vector3(0, 1, 0)
		health = 3
	healthChanged.emit(health)
