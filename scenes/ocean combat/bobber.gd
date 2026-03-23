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
	
	var force_per_probe = float_force / depth_probes.size()
	
	for p in depth_probes:
		var depth = water.get_height(p.global_position) - p.global_position.y
		
		if depth > 0.05:
			submerged = true
			
			var max_depth = 0.9
			
			
			
			depth = clampf(depth, 0.0, 1.0)
			var normalized_depth = pow(clampf(depth / max_depth, 0.0, 1.0), 0.8)
			var r = p.global_position - global_position
			var point_vel = state.linear_velocity + state.angular_velocity.cross(r)
			
			var damping = -point_vel.y * 20
			var force = normalized_depth * (self.mass * gravity * buoyancy_scale / depth_probes.size()) + damping
			
			state.apply_force(Vector3.UP * force, r)
			
			#var angular_damping = -state.angular_velocity * 5.0
			#state.apply_torque(angular_damping)
			
			var pitch_rate = state.angular_velocity.z  # assuming X is pitch
			state.apply_torque(Vector3(-pitch_rate * 50.0, 0, 0))
			
			#state.apply_torque(-state.angular_velocity * 8)
			
			var horizontal_vel = state.linear_velocity
			horizontal_vel.y = 0

			var water_resistance = -horizontal_vel * 2.0
			state.apply_central_force(water_resistance)
	
	if submerged:
		state.linear_velocity *= 1.0 - water_drag
		state.angular_velocity *= 1.0 - water_angular_drag
