class_name WallRunningPlayerState

extends PlayerMovementState

@export var SPEED: float = 35.0
@export var ACCELERATION : float = 0.1
@export var DECELERATION : float = 0.25
@export var DASHINGPLAYERSTATE: DashingPlayerState

@onready var LEFTRAYCAST: RayCast3D = %LeftRayCast
@onready var RIGHTRAYCAST: RayCast3D = %RightRayCast

func update(delta):
	PLAYER.update_gravity(delta, true)
	PLAYER.update_input(SPEED, ACCELERATION, DECELERATION, true)
	PLAYER.update_velocity()
	if PLAYER.velocity.length() == 0:
		transition.emit("IdlePlayerState")
	elif Input.is_action_just_pressed("dash") and DASHINGPLAYERSTATE.getNumCharges() > 0:
		transition.emit("DashingPlayerState")
	elif not (LEFTRAYCAST.is_colliding() or RIGHTRAYCAST.is_colliding()):
		transition.emit("RunningPlayerState")
