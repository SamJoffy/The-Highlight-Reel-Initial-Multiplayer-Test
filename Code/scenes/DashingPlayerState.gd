class_name DashingPlayerState

extends PlayerMovementState

@export var SPEED: float = 150.0
@export var ACCELERATION : float = 0.1
@export var DECELERATION : float = 0.25
@export var DASHLENGTH: float = 0.05
@export var COOLDOWNLENGTH: float = 2.0

var onCooldown: bool = false
var numCharges: int = 2


func enter(PREVIOUSSTATE):
	await get_tree().create_timer(DASHLENGTH).timeout
	transition.emit("RunningPlayerState")

func update(delta):
	PLAYER.update_gravity(delta)
	PLAYER.update_input(SPEED, ACCELERATION, DECELERATION)
	PLAYER.update_velocity()

func exit():
	numCharges -= 1
	await get_tree().create_timer(COOLDOWNLENGTH).timeout
	numCharges += 1

func getNumCharges() -> int:
	return numCharges
