extends BTAgent


const CharacterScript = preload("character.gd")


@export var player : Node3D

var _timer : SceneTreeTimer = null

@onready var navigation_agent : NavigationAgent3D = $"../NavigationAgent3D"
@onready var ray_cast_3d : RayCast3D = $"../RayCast3D"
@onready var enemy : CharacterScript = $".."


func _ready() -> void:
	super._ready()
	debug = true


func _process(delta: float) -> void:
	ray_cast_3d.look_at(player.global_position)

	blackboard.set_value("player_in_sight", ray_cast_3d.get_collider() is CharacterBody3D)

	tick()


func move() -> BTItem.BTState:
	if navigation_agent.is_target_reached():
		return BTItem.BTState.SUCCESS

	var direction : Vector3

	if navigation_agent.is_target_reachable():
		var target := navigation_agent.get_next_path_position() as Vector3
		direction = enemy.global_position.direction_to(target)

		enemy.direction = Vector3(direction.x, 0, direction.z).normalized()
		return BTItem.BTState.RUNNING

	return BTItem.BTState.FAILURE


func wait(value : int) -> BTItem.BTState:
	if _timer == null:
		_timer = get_tree().create_timer(value)

	if _timer.time_left <= 0:
		_timer = null
		return BTItem.BTState.SUCCESS

	return BTItem.BTState.RUNNING


func set_move_target(target : Vector3):
	navigation_agent.target_position = target
