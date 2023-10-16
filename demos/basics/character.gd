extends CharacterBody3D


@export var speed = 10.0

var direction : Vector3

@onready var body : MeshInstance3D = $Body


func _physics_process(delta: float) -> void:
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	if direction != Vector3.ZERO:
		body.look_at(global_position - direction)

	move_and_slide()

	direction = Vector3.ZERO
