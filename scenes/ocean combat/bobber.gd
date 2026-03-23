extends RigidBody3D

@export var float_force : float = 1.4
@export var water_drag : float = 0.05
@export var water_angular_drag : float = 0.05
@export var buoyancy_scale := 1.5  # try 1.2–2.0

@onready var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var water : MeshInstance3D

@onready var depth_probes = $DepthProbes.get_children()

const water_height : float = 0.0
var submerged : bool = false

var smoothed_depths := {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	submerged = false
	
	for p in depth_probes:
		# var depth = water.get_height(p.global_position) - p.global_position.y
		var raw_depth = water.get_height(p.global_position) - p.global_position.y
		var depth = lerp(smoothed_depths.get(p, raw_depth), raw_depth, 0.05)
		smoothed_depths[p] = depth
		
		if depth > 0.05:
			submerged = true
			
			var max_depth = 0.9
			
			var normalized_depth = clampf(depth / max_depth, 0.0, 1.0)
			
			var r = p.global_position - global_position
			
			var force = normalized_depth * (mass * gravity * buoyancy_scale / depth_probes.size())
			
			state.apply_force(Vector3.UP * force, r)

	#central vertical damping (replaces per-probe damping)
	var vertical_vel = state.linear_velocity.y
	state.apply_central_force(Vector3.UP * -vertical_vel * 2000.0)

	#general angular damping
	state.apply_torque(-state.angular_velocity * 8)

	#extra pitch damping
	var pitch_rate = state.angular_velocity.x
	state.apply_torque(Vector3(-pitch_rate * 50.0, 0, 0))

	#horizontal drag
	var hv = state.linear_velocity
	hv.y = 0
	state.apply_central_force(-hv * 2.0)

	if submerged:
		state.linear_velocity *= 1.0 - water_drag
		state.angular_velocity *= 1.0 - water_angular_drag
