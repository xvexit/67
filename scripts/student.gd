extends Node3D

# ---- Main body parts (kept for animation API compat) ----
var body_mesh: MeshInstance3D
var head_mesh: MeshInstance3D
var left_arm: Node3D
var right_arm: Node3D

# ---- Pivots ----
var torso_pivot: Node3D
var head_pivot: Node3D

# ---- Head detail meshes ----
var jaw_mesh: MeshInstance3D
var nose_mesh: MeshInstance3D
var hair_mesh: MeshInstance3D
var hair_mesh2: MeshInstance3D
var left_eye: MeshInstance3D
var right_eye: MeshInstance3D
var mouth_mesh: MeshInstance3D

# ---- Arm detail meshes ----
var left_upper: MeshInstance3D
var left_elbow: MeshInstance3D
var left_lower: MeshInstance3D
var left_hand: MeshInstance3D
var right_upper: MeshInstance3D
var right_elbow: MeshInstance3D
var right_lower: MeshInstance3D
var right_hand: MeshInstance3D

# ---- Arm elbow pivots (for natural bend) ----
var left_elbow_pivot: Node3D
var right_elbow_pivot: Node3D

# ---- Clothing meshes ----
var hood_mesh: MeshInstance3D
var shirt_mesh: MeshInstance3D

# ---- State ----
var student_index: int = 0
var default_position: Vector3
var default_rotation: Vector3
var sitting_y_offset: float = 0.35

# ---- Personality ----
var speed_mod: float = 1.0
var chaos_mod: float = 1.0
var reaction_delay: float = 0.0
var is_panic_type: bool = false
var is_slow_type: bool = false

# ---- Idle animation ----
var idle_timer: float = 0.0
var next_idle_time: float = 2.0
var is_animating: bool = false
var is_standing: bool = false

# ---- Gaze / behavior ----
var is_distractable: bool = false
var base_head_yaw: float = 0.0
var base_head_rotation: Vector3

# ---- 67 pump system ----
var pump_active: bool = false
var pump_timer: float = 0.0
var pump_speed: float = 3.0
var pump_amp: float = 0.3
var pump_base_left: float = 0.0
var pump_base_right: float = 0.0
var pump_offset_r: float = 0.0

# ---- Skin/body color palette ----
var body_colors = [
	Color(0.82, 0.62, 0.42),
	Color(0.72, 0.52, 0.32),
	Color(0.88, 0.68, 0.48),
	Color(0.62, 0.42, 0.28),
	Color(0.78, 0.58, 0.38),
	Color(0.68, 0.48, 0.35),
	Color(0.92, 0.72, 0.52),
	Color(0.55, 0.38, 0.28),
	Color(0.85, 0.65, 0.45),
	Color(0.75, 0.55, 0.38),
	Color(0.9, 0.7, 0.5),
	Color(0.58, 0.4, 0.3),
]

# ---- Hoodie/clothing color palette ----
var clothing_colors = [
	Color(0.22, 0.55, 0.28),
	Color(0.55, 0.25, 0.22),
	Color(0.25, 0.25, 0.35),
	Color(0.6, 0.45, 0.2),
	Color(0.3, 0.3, 0.3),
	Color(0.55, 0.35, 0.45),
	Color(0.2, 0.4, 0.5),
	Color(0.45, 0.45, 0.25),
	Color(0.35, 0.25, 0.2),
	Color(0.5, 0.2, 0.2),
	Color(0.2, 0.3, 0.2),
	Color(0.4, 0.4, 0.4),
]

var hairstyles := ["messy", "undercut", "fluffy", "bangs", "long"]

func build(index: int):
	student_index = index
	default_position = position
	default_rotation = rotation

	speed_mod = randf_range(0.6, 1.4)
	chaos_mod = randf_range(0.7, 1.8)
	reaction_delay = randf_range(0.0, 0.4) * speed_mod
	is_panic_type = randf() < 0.25
	is_slow_type = randf() < 0.15

	var body_color = body_colors[index % body_colors.size()]
	var cloth_color = clothing_colors[index % clothing_colors.size()]
	var skin_bright = Color(
		min(1.0, body_color.r * 1.2),
		min(1.0, body_color.g * 1.15),
		min(1.0, body_color.b * 1.1)
	)
	var sit = sitting_y_offset

# ========== TORSO PIVOT ==========
	torso_pivot = Node3D.new()
	torso_pivot.name = "TorsoPivot"
	torso_pivot.position = Vector3(0.0, 0.15 + sit, 0.0)
	add_child(torso_pivot)

# ========== TORSO / CHEST ==========
	var chest_mat = StandardMaterial3D.new()
	chest_mat.albedo_color = cloth_color
	chest_mat.roughness = 0.8

	var chest = BoxMesh.new()
	chest.size = Vector3(0.32, 0.34, 0.20)
	chest.material = chest_mat

	body_mesh = MeshInstance3D.new()
	body_mesh.name = "Body"
	body_mesh.mesh = chest
	body_mesh.position = Vector3(0.0, 0.18, 0.0)
	torso_pivot.add_child(body_mesh)

# ========== SHOULDERS ==========
	var shoulder_mat = StandardMaterial3D.new()
	shoulder_mat.albedo_color = cloth_color
	shoulder_mat.roughness = 0.8

	var shoulders = BoxMesh.new()
	shoulders.size = Vector3(0.46, 0.04, 0.20)
	shoulders.material = shoulder_mat

	var shoulder_mesh = MeshInstance3D.new()
	shoulder_mesh.name = "Shoulders"
	shoulder_mesh.mesh = shoulders
	shoulder_mesh.position = Vector3(0.0, 0.34, 0.0)
	torso_pivot.add_child(shoulder_mesh)

# ========== HOOD (hoodie back) ==========
	var hood_mat = StandardMaterial3D.new()
	hood_mat.albedo_color = cloth_color
	hood_mat.roughness = 0.9

	var hood = SphereMesh.new()
	hood.radius = 0.08
	hood.height = 0.14

	hood_mesh = MeshInstance3D.new()
	hood_mesh.name = "Hood"
	hood_mesh.mesh = hood
	hood_mesh.position = Vector3(0.0, 0.36, -0.08)
	hood_mesh.scale = Vector3(1.0, 0.6, 0.5)
	torso_pivot.add_child(hood_mesh)

# ========== SHIRT COLLAR ==========
	var collar_mat = StandardMaterial3D.new()
	var collar_bright = Color(
		min(1.0, cloth_color.r * 1.5),
		min(1.0, cloth_color.g * 1.5),
		min(1.0, cloth_color.b * 1.5)
	)
	collar_mat.albedo_color = collar_bright
	collar_mat.roughness = 0.6

	var collar = BoxMesh.new()
	collar.size = Vector3(0.12, 0.06, 0.14)
	collar.material = collar_mat

	var collar_mesh = MeshInstance3D.new()
	collar_mesh.name = "Collar"
	collar_mesh.mesh = collar
	collar_mesh.position = Vector3(0.0, 0.33, 0.0)
	torso_pivot.add_child(collar_mesh)

# ========== NECK ==========
	var neck_mat = StandardMaterial3D.new()
	neck_mat.albedo_color = skin_bright
	neck_mat.roughness = 0.6

	var neck = CylinderMesh.new()
	neck.top_radius = 0.025
	neck.bottom_radius = 0.035
	neck.height = 0.06
	neck.material = neck_mat

	var neck_mesh = MeshInstance3D.new()
	neck_mesh.name = "Neck"
	neck_mesh.mesh = neck
	neck_mesh.position = Vector3(0.0, 0.38, 0.0)
	torso_pivot.add_child(neck_mesh)

# ========== HEAD PIVOT ==========
	head_pivot = Node3D.new()
	head_pivot.name = "HeadPivot"
	head_pivot.position = Vector3(0.0, 0.41, 0.0)
	torso_pivot.add_child(head_pivot)

# ========== HEAD ==========
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = skin_bright
	head_mat.roughness = 0.55

	var head = SphereMesh.new()
	head.radius = 0.10
	head.height = 0.22
	head.material = head_mat

	head_mesh = MeshInstance3D.new()
	head_mesh.name = "Head"
	head_mesh.mesh = head
	head_mesh.position = Vector3(0.0, 0.08, 0.0)
	head_mesh.scale = Vector3(1.0, 1.0, 0.85)
	head_pivot.add_child(head_mesh)

# ========== JAW ==========
	var jaw_mat = StandardMaterial3D.new()
	jaw_mat.albedo_color = skin_bright
	jaw_mat.roughness = 0.6

	var jaw = BoxMesh.new()
	jaw.size = Vector3(0.14, 0.04, 0.10)
	jaw.material = jaw_mat

	jaw_mesh = MeshInstance3D.new()
	jaw_mesh.name = "Jaw"
	jaw_mesh.mesh = jaw
	jaw_mesh.position = Vector3(0.0, -0.04, 0.04)
	head_pivot.add_child(jaw_mesh)

# ========== NOSE ==========
	var nose_mat = StandardMaterial3D.new()
	nose_mat.albedo_color = Color(
		min(1.0, skin_bright.r * 0.9),
		min(1.0, skin_bright.g * 0.88),
		min(1.0, skin_bright.b * 0.85)
	)
	nose_mat.roughness = 0.6

	var nose = BoxMesh.new()
	nose.size = Vector3(0.025, 0.025, 0.03)
	nose.material = nose_mat

	nose_mesh = MeshInstance3D.new()
	nose_mesh.name = "Nose"
	nose_mesh.mesh = nose
	nose_mesh.position = Vector3(0.0, 0.06, 0.12)
	head_pivot.add_child(nose_mesh)

# ========== EYES ==========
	var eye_white_mat = StandardMaterial3D.new()
	eye_white_mat.albedo_color = Color(0.95, 0.93, 0.9)
	eye_white_mat.roughness = 0.3

	var eye_mat = StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.12, 0.1, 0.08)
	eye_mat.roughness = 0.2

	for side in [-1, 1]:
		var eye_white = MeshInstance3D.new()
		eye_white.name = "EyeWhite_" + str(side)
		eye_white.mesh = SphereMesh.new()
		eye_white.mesh.radius = 0.025
		eye_white.mesh.height = 0.035
		eye_white.mesh.material = eye_white_mat
		eye_white.position = Vector3(side * 0.05, 0.085, 0.12)
		head_pivot.add_child(eye_white)

		var pupil = MeshInstance3D.new()
		pupil.name = "Pupil_" + str(side)
		pupil.mesh = SphereMesh.new()
		pupil.mesh.radius = 0.012
		pupil.mesh.height = 0.016
		pupil.mesh.material = eye_mat
		pupil.position = Vector3(side * 0.05, 0.083, 0.14)
		head_pivot.add_child(pupil)

		if side == -1:
			left_eye = eye_white
		else:
			right_eye = eye_white

# ========== MOUTH ==========
	var mouth_mat = StandardMaterial3D.new()
	mouth_mat.albedo_color = Color(0.4, 0.28, 0.24)
	mouth_mat.roughness = 0.5

	var mouth = BoxMesh.new()
	mouth.size = Vector3(0.04, 0.008, 0.015)
	mouth.material = mouth_mat

	mouth_mesh = MeshInstance3D.new()
	mouth_mesh.name = "Mouth"
	mouth_mesh.mesh = mouth
	mouth_mesh.position = Vector3(0.0, 0.02, 0.12)
	head_pivot.add_child(mouth_mesh)

# ========== HAIR ==========
	_build_hair(skin_bright, cloth_color)

# ========== GAZE DIRECTION ==========
	is_distractable = randf() < 0.3
	var angle_to_board = atan2(-default_position.x, -(2.8 + default_position.z))
	rotation.y = angle_to_board
	default_rotation.y = angle_to_board
	base_head_rotation = Vector3.ZERO
	head_pivot.rotation = base_head_rotation

# ========== LEFT ARM ==========
	left_arm = Node3D.new()
	left_arm.name = "LeftArm"
	left_arm.position = Vector3(-0.23, 0.30, 0.0)
	torso_pivot.add_child(left_arm)

	var arm_mat = StandardMaterial3D.new()
	arm_mat.albedo_color = cloth_color
	arm_mat.roughness = 0.7

	var skin_arm_mat = StandardMaterial3D.new()
	skin_arm_mat.albedo_color = skin_bright
	skin_arm_mat.roughness = 0.6

	var upper = CylinderMesh.new()
	upper.top_radius = 0.022
	upper.bottom_radius = 0.018
	upper.height = 0.12
	upper.material = arm_mat

	left_upper = MeshInstance3D.new()
	left_upper.name = "LeftUpperArm"
	left_upper.mesh = upper
	left_upper.position = Vector3(0.0, -0.06, 0.0)
	left_arm.add_child(left_upper)

	left_elbow_pivot = Node3D.new()
	left_elbow_pivot.name = "LeftElbowPivot"
	left_elbow_pivot.position = Vector3(0.0, -0.12, 0.0)
	left_arm.add_child(left_elbow_pivot)

	var elbow_s = SphereMesh.new()
	elbow_s.radius = 0.016
	elbow_s.height = 0.025
	elbow_s.material = skin_arm_mat

	left_elbow = MeshInstance3D.new()
	left_elbow.name = "LeftElbow"
	left_elbow.mesh = elbow_s
	left_elbow.position = Vector3(0.0, 0.0, 0.0)
	left_arm.add_child(left_elbow)

	var lower = CylinderMesh.new()
	lower.top_radius = 0.018
	lower.bottom_radius = 0.014
	lower.height = 0.10
	lower.material = skin_arm_mat

	left_lower = MeshInstance3D.new()
	left_lower.name = "LeftLowerArm"
	left_lower.mesh = lower
	left_lower.position = Vector3(0.0, -0.05, 0.0)
	left_elbow_pivot.add_child(left_lower)

	var hand_m = BoxMesh.new()
	hand_m.size = Vector3(0.025, 0.032, 0.015)
	hand_m.material = skin_arm_mat

	left_hand = MeshInstance3D.new()
	left_hand.name = "LeftHand"
	left_hand.mesh = hand_m
	left_hand.position = Vector3(0.0, -0.10, 0.005)
	left_elbow_pivot.add_child(left_hand)

# ========== RIGHT ARM ==========
	right_arm = Node3D.new()
	right_arm.name = "RightArm"
	right_arm.position = Vector3(0.23, 0.30, 0.0)
	torso_pivot.add_child(right_arm)

	var arm_mat2 = StandardMaterial3D.new()
	arm_mat2.albedo_color = cloth_color
	arm_mat2.roughness = 0.7

	var skin_arm_mat2 = StandardMaterial3D.new()
	skin_arm_mat2.albedo_color = skin_bright
	skin_arm_mat2.roughness = 0.6

	var upper2 = CylinderMesh.new()
	upper2.top_radius = 0.022
	upper2.bottom_radius = 0.018
	upper2.height = 0.12
	upper2.material = arm_mat2

	right_upper = MeshInstance3D.new()
	right_upper.name = "RightUpperArm"
	right_upper.mesh = upper2
	right_upper.position = Vector3(0.0, -0.06, 0.0)
	right_arm.add_child(right_upper)

	right_elbow_pivot = Node3D.new()
	right_elbow_pivot.name = "RightElbowPivot"
	right_elbow_pivot.position = Vector3(0.0, -0.12, 0.0)
	right_arm.add_child(right_elbow_pivot)

	var elbow_s2 = SphereMesh.new()
	elbow_s2.radius = 0.016
	elbow_s2.height = 0.025
	elbow_s2.material = skin_arm_mat2

	right_elbow = MeshInstance3D.new()
	right_elbow.name = "RightElbow"
	right_elbow.mesh = elbow_s2
	right_elbow.position = Vector3(0.0, 0.0, 0.0)
	right_arm.add_child(right_elbow)

	var lower2 = CylinderMesh.new()
	lower2.top_radius = 0.018
	lower2.bottom_radius = 0.014
	lower2.height = 0.10
	lower2.material = skin_arm_mat2

	right_lower = MeshInstance3D.new()
	right_lower.name = "RightLowerArm"
	right_lower.mesh = lower2
	right_lower.position = Vector3(0.0, -0.05, 0.0)
	right_elbow_pivot.add_child(right_lower)

	var hand_m2 = BoxMesh.new()
	hand_m2.size = Vector3(0.025, 0.032, 0.015)
	hand_m2.material = skin_arm_mat2

	right_hand = MeshInstance3D.new()
	right_hand.name = "RightHand"
	right_hand.mesh = hand_m2
	right_hand.position = Vector3(0.0, -0.10, 0.005)
	right_elbow_pivot.add_child(right_hand)

# ========== INITIAL POSE VARIATION ==========
	var slouch = randf_range(0.02, 0.07)
	var asymmetry = randf_range(-0.03, 0.03)
	torso_pivot.rotation.x = slouch
	torso_pivot.rotation.z = asymmetry

	if randf() < 0.25:
		left_arm.rotation.x = randf_range(-0.6, -0.3)
		left_arm.rotation.z = randf_range(-0.15, 0.15)
		head_pivot.rotation.z = randf_range(-0.03, 0.03)
		head_pivot.rotation.x = randf_range(0.02, 0.06)
	elif randf() < 0.2:
		right_arm.rotation.x = randf_range(-0.6, -0.3)
		right_arm.rotation.z = randf_range(-0.15, 0.15)
	else:
		left_arm.rotation.x = randf_range(-0.12, -0.03)
		right_arm.rotation.x = randf_range(-0.12, -0.03)

	if is_slow_type:
		torso_pivot.rotation.x += 0.03

# ========== INIT TIMERS ==========
	idle_timer = randf_range(0.0, 2.0)
	if is_distractable:
		next_idle_time = randf_range(5.0, 12.0)
	else:
		next_idle_time = randf_range(12.0, 25.0)


# ============================================================
# HAIR BUILDER — 5 hairstyles
# ============================================================
func _build_hair(_skin_color: Color, _cloth_color: Color):
	var hair_style = hairstyles[student_index % hairstyles.size()]
	var hair_mat = StandardMaterial3D.new()
	var hair_shade = randf_range(0.05, 0.35)
	hair_mat.albedo_color = Color(hair_shade, hair_shade * 0.85, hair_shade * 0.7)
	hair_mat.roughness = 0.85

# ---- All students get a base hair cap ----
	var base_hair = SphereMesh.new()
	base_hair.radius = 0.14
	base_hair.height = 0.18
	base_hair.material = hair_mat
	hair_mesh = MeshInstance3D.new()
	hair_mesh.name = "HairBase"
	hair_mesh.mesh = base_hair
	hair_mesh.position = Vector3(0.0, 0.12, 0.0)
	hair_mesh.scale = Vector3(1.1, 0.7, 1.1)
	head_pivot.add_child(hair_mesh)

# ---- Style-specific extras ----
	match hair_style:
		"messy":
			var spike1 = BoxMesh.new()
			spike1.size = Vector3(0.03, 0.04, 0.02)
			spike1.material = hair_mat
			var s1 = MeshInstance3D.new()
			s1.name = "HairSpike1"
			s1.mesh = spike1
			s1.position = Vector3(0.04, 0.13, -0.04)
			s1.rotation.z = -0.25
			head_pivot.add_child(s1)

			var spike2 = BoxMesh.new()
			spike2.size = Vector3(0.025, 0.035, 0.02)
			spike2.material = hair_mat
			var s2 = MeshInstance3D.new()
			s2.name = "HairSpike2"
			s2.mesh = spike2
			s2.position = Vector3(-0.035, 0.13, 0.0)
			s2.rotation.z = 0.2
			head_pivot.add_child(s2)

		"long":
			hair_mesh.scale = Vector3(1.0, 0.6, 0.85)
			hair_mesh.position.y = 0.09

			var fringe = BoxMesh.new()
			fringe.size = Vector3(0.12, 0.04, 0.02)
			fringe.material = hair_mat
			var f = MeshInstance3D.new()
			f.name = "HairFringe"
			f.mesh = fringe
			f.position = Vector3(0.0, 0.08, 0.08)
			head_pivot.add_child(f)

			var side_l = BoxMesh.new()
			side_l.size = Vector3(0.03, 0.09, 0.05)
			side_l.material = hair_mat
			var sl = MeshInstance3D.new()
			sl.name = "HairSideL"
			sl.mesh = side_l
			sl.position = Vector3(-0.08, 0.03, 0.0)
			sl.rotation.z = 0.08
			head_pivot.add_child(sl)

			var side_r = sl.duplicate()
			side_r.name = "HairSideR"
			side_r.position.x = 0.08
			side_r.rotation.z = -0.08
			head_pivot.add_child(side_r)

		"undercut":
			hair_mesh.scale = Vector3(1.0, 0.45, 0.9)
			hair_mesh.position.y = 0.10

			var top_vol = BoxMesh.new()
			top_vol.size = Vector3(0.10, 0.04, 0.07)
			top_vol.material = hair_mat
			var tv = MeshInstance3D.new()
			tv.name = "HairTopVolume"
			tv.mesh = top_vol
			tv.position = Vector3(0.0, 0.10, -0.01)
			tv.rotation.x = -0.15
			head_pivot.add_child(tv)

			var fringe = BoxMesh.new()
			fringe.size = Vector3(0.08, 0.03, 0.015)
			fringe.material = hair_mat
			var f = MeshInstance3D.new()
			f.name = "HairFringeU"
			f.mesh = fringe
			f.position = Vector3(randf_range(-0.02, 0.02), 0.08, 0.08)
			head_pivot.add_child(f)

		"fluffy":
			hair_mesh.scale = Vector3(1.05, 0.55, 0.95)
			hair_mesh.position = Vector3(0.0, 0.10, -0.03)

			var puff = SphereMesh.new()
			puff.radius = 0.04
			puff.height = 0.05
			puff.material = hair_mat
			var p = MeshInstance3D.new()
			p.name = "HairPuff"
			p.mesh = puff
			p.position = Vector3(0.0, 0.13, 0.0)
			head_pivot.add_child(p)

			var puff2 = p.duplicate()
			puff2.name = "HairPuff2"
			puff2.position.x = 0.045
			puff2.position.z = -0.02
			head_pivot.add_child(puff2)

			var puff3 = p.duplicate()
			puff3.name = "HairPuff3"
			puff3.position.x = -0.045
			puff3.position.z = -0.02
			head_pivot.add_child(puff3)

		"bangs":
			hair_mesh.scale = Vector3(1.0, 0.5, 0.85)

			var bangs = BoxMesh.new()
			bangs.size = Vector3(0.12, 0.04, 0.015)
			bangs.material = hair_mat
			var b = MeshInstance3D.new()
			b.name = "HairBangs"
			b.mesh = bangs
			b.position = Vector3(0.0, 0.08, 0.09)
			b.rotation.x = -0.1
			head_pivot.add_child(b)

			var bangs_side_l = BoxMesh.new()
			bangs_side_l.size = Vector3(0.02, 0.05, 0.04)
			bangs_side_l.material = hair_mat
			var bl = MeshInstance3D.new()
			bl.name = "HairBangsSideL"
			bl.mesh = bangs_side_l
			bl.position = Vector3(-0.06, 0.05, 0.07)
			bl.rotation.z = 0.15
			head_pivot.add_child(bl)

			var br = bl.duplicate()
			br.name = "HairBangsSideR"
			br.position.x = 0.06
			br.rotation.z = -0.15
			head_pivot.add_child(br)

# ---- Dye chance ----
	if randf() < 0.15 and hair_mesh:
		var dye_mat = hair_mat.duplicate()
		dye_mat.albedo_color = Color(
			randf_range(0.4, 0.9),
			randf_range(0.1, 0.3),
			randf_range(0.1, 0.3)
		)
		hair_mesh.set_surface_override_material(0, dye_mat)


# ============================================================
# _process — idle + pump
# ============================================================
func _process(delta):
	if pump_active:
		pump_timer += delta * pump_speed
		var pump = sin(pump_timer * TAU) * pump_amp
		if is_instance_valid(left_arm):
			left_arm.rotation.x = pump_base_left + pump
		if is_instance_valid(right_arm):
			right_arm.rotation.x = pump_base_right + pump * 0.7 + sin(pump_timer * TAU * 1.37 + pump_offset_r) * pump_amp * 0.35
		_update_elbow_bend()

	if is_animating or is_standing:
		return

	idle_timer += delta
	if idle_timer >= next_idle_time:
		idle_timer = 0.0
		next_idle_time = randf_range(1.0, 4.0)
		_play_idle_movement()


func _update_elbow_bend():
	if is_instance_valid(left_elbow_pivot):
		left_elbow_pivot.rotation.x = abs(left_arm.rotation.x) * 0.3
	if is_instance_valid(right_elbow_pivot):
		right_elbow_pivot.rotation.x = abs(right_arm.rotation.x) * 0.3


func _play_idle_movement():
	if is_animating or is_standing:
		return

	var dur = randf_range(0.2, 0.5) * speed_mod

	if is_distractable and randf() < 0.5:
		var action = randi() % 4
		match action:
			0:
				_head_look(Vector3(randf_range(0.2, 0.4), 0.0, 0.0), dur)
			1:
				_head_look(Vector3(randf_range(-0.4, -0.2), 0.0, 0.0), dur)
			2:
				_head_look(Vector3(0.0, randf_range(0.15, 0.3), 0.0), dur)
			3:
				_torso_sway(randf_range(-0.05, 0.05), dur)
	else:
		_torso_sway(randf_range(-0.03, 0.03), dur * 0.5)


func _head_look(target: Vector3, duration: float):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(head_pivot, "rotation", target, duration)
	tween.tween_interval(randf_range(0.5, 1.5))
	var return_tween = create_tween()
	return_tween.set_ease(Tween.EASE_IN_OUT)
	return_tween.set_trans(Tween.TRANS_SINE)
	return_tween.tween_property(head_pivot, "rotation", base_head_rotation, duration * 0.7)


func _torso_sway(amount: float, duration: float):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(torso_pivot, "rotation:z", amount, duration)
	tween.tween_interval(randf_range(0.3, 0.8))
	var return_tween = create_tween()
	return_tween.set_ease(Tween.EASE_IN_OUT)
	return_tween.set_trans(Tween.TRANS_SINE)
	return_tween.tween_property(torso_pivot, "rotation:z", 0.0, duration * 0.5)


# ============================================================
# 67 POSE
# ============================================================
func do_sixtyseven_pose(rage_ratio: float = 0.5):
	is_standing = true
	is_animating = true

	var rage_chaos = 1.0 + rage_ratio * 0.6

	var delay = reaction_delay * randf_range(0.3, 2.0) / rage_chaos
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout

	if not is_instance_valid(self):
		return

# ---- 1. STAND UP ----
	var stand_height = 0.4 + randf_range(0.25, 0.45) * chaos_mod
	var chair_slide = randf_range(0.03, 0.1) * chaos_mod

	var rise = create_tween()
	rise.set_ease(Tween.EASE_OUT)
	rise.set_trans(Tween.TRANS_BACK)
	rise.tween_property(self, "position:y", stand_height, 0.08 / speed_mod)
	rise.parallel().tween_property(self, "position:z", default_position.z + chair_slide, 0.1 / speed_mod)

	var lurch = create_tween()
	lurch.set_ease(Tween.EASE_OUT)
	lurch.set_trans(Tween.TRANS_BACK)
	lurch.tween_property(torso_pivot, "rotation:x", randf_range(0.04, 0.12) * chaos_mod, 0.06 / speed_mod)

# ---- 2. ARMS OUT ----
	var arm_speed = 0.06 / speed_mod
	var left_target = -1.2 + randf_range(-0.3, 0.3) * chaos_mod * rage_chaos
	var right_target = -0.9 + randf_range(-0.4, 0.4) * chaos_mod * rage_chaos
	var left_elbow_t = 0.25 + randf_range(-0.1, 0.15) * chaos_mod
	var right_elbow_t = -0.25 + randf_range(-0.15, 0.1) * chaos_mod

	var arms_out = create_tween()
	arms_out.set_ease(Tween.EASE_OUT)
	arms_out.set_trans(Tween.TRANS_BACK)
	arms_out.tween_property(left_arm, "rotation:x", left_target, arm_speed)
	arms_out.parallel().tween_property(left_arm, "rotation:z", left_elbow_t, arm_speed)
	arms_out.tween_property(right_arm, "rotation:x", right_target, arm_speed * 1.2)
	arms_out.parallel().tween_property(right_arm, "rotation:z", right_elbow_t, arm_speed)

# ---- 3. PUMP SETUP ----
	pump_base_left = left_target
	pump_base_right = right_target
	pump_amp = 0.2 * chaos_mod * rage_chaos + randf_range(0.0, 0.15)
	pump_speed = 2.5 + randf_range(0.0, 2.5) / speed_mod
	pump_offset_r = randf_range(0.0, 1.0)
	pump_timer = 0.0
	pump_active = true

	if is_slow_type:
		pump_speed *= 0.5

# ---- 4. CHAOTIC EXTRAS ----
	var wobble_loops = 2 + randi() % int(3 * rage_chaos)
	var wobble = create_tween()
	wobble.set_loops(wobble_loops)
	var wobble_amp = 0.06 * chaos_mod * rage_chaos
	wobble.tween_property(torso_pivot, "rotation:z", wobble_amp, 0.05)
	wobble.tween_property(torso_pivot, "rotation:z", -wobble_amp * 0.7, 0.06)
	wobble.tween_property(torso_pivot, "rotation:z", wobble_amp * 0.4, 0.04)
	wobble.tween_property(torso_pivot, "rotation:z", 0.0, 0.05)

	var head_tilt = create_tween()
	head_tilt.set_ease(Tween.EASE_OUT)
	head_tilt.set_trans(Tween.TRANS_BACK)
	head_tilt.tween_property(head_pivot, "rotation:x", randf_range(0.05, 0.18) * chaos_mod, 0.08)
	if randf() < 0.6:
		var head_turn = create_tween()
		head_turn.set_ease(Tween.EASE_OUT)
		head_turn.set_trans(Tween.TRANS_BACK)
		head_turn.tween_property(head_pivot, "rotation:y", randf_range(-0.2, 0.2) * chaos_mod, 0.1)

	if is_panic_type or randf() < 0.35 * rage_chaos:
		var shake_loops = 3 + randi() % int(4 * rage_chaos)
		var shake = create_tween()
		shake.set_loops(shake_loops)
		var s = 0.12 * chaos_mod * rage_chaos
		shake.tween_property(left_arm, "rotation:z", s, 0.03)
		shake.tween_property(right_arm, "rotation:z", -s, 0.03)
		shake.tween_property(left_arm, "rotation:z", -s, 0.03)
		shake.tween_property(right_arm, "rotation:z", s, 0.03)

	if randf() < 0.2:
		var glance = create_tween()
		glance.set_ease(Tween.EASE_OUT)
		glance.set_trans(Tween.TRANS_BACK)
		glance.tween_property(head_pivot, "rotation:y", randf_range(-0.5, 0.5), 0.04)

# ---- 5. LABEL ----
	var label = Label3D.new()
	label.name = "SixtySevenLabel"
	label.text = "67"
	label.font_size = 28
	label.modulate = Color(1.0, 0.2, 0.1)
	label.outline_size = 2
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.005
	label.position = Vector3(0.0, 0.65 + sitting_y_offset, 0.0)
	add_child(label)

	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(label):
			label.queue_free()
	)

	is_animating = false


# ============================================================
# LAUGH
# ============================================================
func do_laugh():
	is_animating = true

	var laugh_type = randi() % 3

	match laugh_type:
		0:
			var tween = create_tween()
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.set_loops(4)
			tween.tween_property(torso_pivot, "rotation:x", 0.12 * chaos_mod, 0.08)
			tween.tween_property(torso_pivot, "rotation:x", -0.08 * chaos_mod, 0.08)
			tween.tween_property(torso_pivot, "rotation:x", 0.0, 0.08)

		1:
			var point_tween = create_tween()
			point_tween.set_ease(Tween.EASE_OUT)
			point_tween.set_trans(Tween.TRANS_BACK)

			if randf() > 0.5:
				point_tween.tween_property(left_arm, "rotation:x", -1.2, 0.1)
			else:
				point_tween.tween_property(right_arm, "rotation:x", 1.2, 0.1)

			var shake_tween = create_tween()
			shake_tween.set_loops(3)
			shake_tween.tween_property(torso_pivot, "rotation:x", 0.1, 0.07)
			shake_tween.tween_property(torso_pivot, "rotation:x", 0.0, 0.07)

		2:
			var tween = create_tween()
			tween.set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(torso_pivot, "rotation:z", -0.1 * chaos_mod, 0.12)
			tween.parallel().tween_property(head_pivot, "rotation:x", 0.2, 0.12)

			var shake_tween = create_tween()
			shake_tween.set_loops(4)
			shake_tween.tween_property(head_pivot, "rotation:y", 0.15, 0.06)
			shake_tween.tween_property(head_pivot, "rotation:y", -0.15, 0.06)

	var bounce_tween = create_tween()
	bounce_tween.set_loops(3)
	bounce_tween.tween_property(self, "position:y", 0.04, 0.08)
	bounce_tween.tween_property(self, "position:y", 0.0, 0.08)

	var reset_timer = get_tree().create_timer(1.5)
	reset_timer.timeout.connect(_reset_laugh)


func _reset_laugh():
	if not is_instance_valid(self):
		return
	_reset_arms_and_torso()
	is_animating = false


func reset_pose():
	is_standing = false
	pump_active = false
	is_animating = true

	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)

	tween.parallel().tween_property(self, "position", default_position, 0.3)
	tween.parallel().tween_property(self, "rotation", default_rotation, 0.2)

	if randf() < 0.5 * chaos_mod:
		var stumble = create_tween()
		stumble.set_ease(Tween.EASE_IN_OUT)
		var s = 0.1 * chaos_mod
		stumble.tween_property(torso_pivot, "rotation:z", s, 0.06)
		stumble.tween_property(torso_pivot, "rotation:z", -s * 0.5, 0.08)
		stumble.tween_property(torso_pivot, "rotation:z", 0.0, 0.06)

	_reset_arms_and_torso()

	for child in get_children():
		if child.name == "SixtySevenLabel":
			child.queue_free()

	await get_tree().create_timer(0.4).timeout

	if is_instance_valid(self):
		is_animating = false


func _reset_arms_and_torso():
	if is_instance_valid(left_arm):
		var tween_l = create_tween()
		tween_l.set_ease(Tween.EASE_OUT)
		tween_l.set_trans(Tween.TRANS_SINE)
		tween_l.tween_property(left_arm, "rotation", Vector3.ZERO, 0.2)

	if is_instance_valid(right_arm):
		var tween_r = create_tween()
		tween_r.set_ease(Tween.EASE_OUT)
		tween_r.set_trans(Tween.TRANS_SINE)
		tween_r.tween_property(right_arm, "rotation", Vector3.ZERO, 0.2)

	if is_instance_valid(torso_pivot):
		var tween_t = create_tween()
		tween_t.set_ease(Tween.EASE_OUT)
		tween_t.set_trans(Tween.TRANS_SINE)
		tween_t.tween_property(torso_pivot, "rotation", Vector3.ZERO, 0.2)

	if is_instance_valid(head_pivot):
		var tween_h = create_tween()
		tween_h.set_ease(Tween.EASE_OUT)
		tween_h.set_trans(Tween.TRANS_SINE)
		tween_h.tween_property(head_pivot, "rotation", base_head_rotation, 0.2)

	if is_instance_valid(left_elbow_pivot):
		var tween_e = create_tween()
		tween_e.set_ease(Tween.EASE_OUT)
		tween_e.set_trans(Tween.TRANS_SINE)
		tween_e.tween_property(left_elbow_pivot, "rotation", Vector3.ZERO, 0.2)

	if is_instance_valid(right_elbow_pivot):
		var tween_e = create_tween()
		tween_e.set_ease(Tween.EASE_OUT)
		tween_e.set_trans(Tween.TRANS_SINE)
		tween_e.tween_property(right_elbow_pivot, "rotation", Vector3.ZERO, 0.2)
