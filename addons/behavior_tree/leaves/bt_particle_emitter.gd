@tool
class_name BTParticleEmitter
extends BTLeaf

## Emits particles in the [GPUParticles2D], [GPUParticles3D], [CPUParticles2D] or [CPUParticles3D]
## found in the [member BTAgent.blackboard] with [member key].
## Returns SUCCESS if the particles have finished emitting and FAILURE if no particle emitter is found.
## Returns RUNNING while the particle emitter is emitting, if it is not one_shot, will keep RUNNING
## until it's aborted.



@export var key : String = ""
@export var stop_on_abort := true

var _particle_system
var _started : bool



func _get_bt_type_name() -> String:
	return "Particle Emitter"


func _execute_tick(agent : BTAgent) -> void:
	if _particle_system == null:
		_report_result(agent, BTState.FAILURE)
		return

	if not _started:
		_particle_system.emitting = true
		_started = true

	if _particle_system.emitting:
		_report_result(agent, BTState.RUNNING)
	else:
		_report_result(agent, BTState.SUCCESS)


func _abort(agent : BTAgent) -> void:
	if not stop_on_abort: return

	_particle_system = agent.get_node_memory(self)
	_particle_system.emitting = false


func _setup_execution(agent : BTAgent) -> void:
	if agent.has_node_memory(self):
		_particle_system = agent.get_node_memory(self)
		_started = true
	else:
		_particle_system = agent.blackboard.get_value(key)
		_started = false

		if (
				not _particle_system is GPUParticles2D
				and not _particle_system is GPUParticles3D
				and not _particle_system is CPUParticles2D
				and not _particle_system is CPUParticles3D
		):
			push_error("BTParticleEmitter: key is not a particle emitter.")
			_particle_system = null


func _save_memory(agent : BTAgent) -> void:
	agent.set_node_memory(self, _particle_system)
