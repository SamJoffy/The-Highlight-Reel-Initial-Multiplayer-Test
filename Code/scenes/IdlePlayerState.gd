class_name IdlePlayerState

extends PlayerMovementState

@export var SPEED: float = 10.0
@export var ACCELERATION : float = 0.1
@export var DECELERATION : float = 0.25

func update(delta):
	PLAYER.update_gravity(delta)
	PLAYER.update_input(SPEED, ACCELERATION, DECELERATION)
	PLAYER.update_velocity()
	if PLAYER.velocity.length() > 0.0:
		transition.emit("RunningPlayerState")
