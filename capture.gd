extends Node3D


@onready var _hand : Node3D = %LeftHand
@onready var _skeleton : Skeleton3D = %LeftHand/LeftHandOpenXR/Skeleton3D
@onready var _left_mirror : Node3D = %LeftMirrorHand
@onready var _right_mirror : Node3D = %RightMirrorHand
@onready var _left_player : AnimationPlayer = %LeftMirrorHand/AnimationPlayer
@onready var _right_player : AnimationPlayer = %RightMirrorHand/AnimationPlayer
@onready var _left_library : AnimationLibrary
@onready var _right_library : AnimationLibrary
@onready var _left_animation : Animation
@onready var _right_animation : Animation

var _xr_interface: XRInterface
var _save_countdown : float = -1.0
var _save_index : int = 1


func _ready() -> void:
	_start_xr()

	# Configure the left hand animation
	_left_animation = Animation.new()
	_left_animation.loop_mode = Animation.LOOP_LINEAR
	_left_library = AnimationLibrary.new()
	_left_library.add_animation("HandPose", _left_animation)
	_left_player.add_animation_library("HandPoseLibrary", _left_library)
	_left_player.current_animation = "HandPoseLibrary/HandPose"

	# Configure the right hand animation
	_right_animation = Animation.new()
	_right_animation.loop_mode = Animation.LOOP_LINEAR
	_right_library = AnimationLibrary.new()
	_right_library.add_animation("HandPose", _right_animation)
	_right_player.add_animation_library("HandPoseLibrary", _right_library)
	_right_player.current_animation = "HandPoseLibrary/HandPose"


func _process(delta : float) -> void:
	# Update the mirror hands
	_left_mirror.global_position = _hand.global_position + Vector3(0.0, 0.2, 0.0)
	_left_mirror.global_rotation = _hand.global_rotation
	_right_mirror.global_position = _hand.global_position + Vector3(0.2, 0.2, 0.0)
	_right_mirror.global_rotation = _hand.global_rotation * Basis(Vector3.LEFT, PI)

	# Copy the animation bones
	_copy_bone("Palm")
	_copy_bone("Wrist")
	_copy_bone("Thumb_Metacarpal")
	_copy_bone("Thumb_Proximal")
	_copy_bone("Thumb_Distal")
	_copy_bone("Thumb_Tip")
	_copy_bone("Index_Metacarpal")
	_copy_bone("Index_Proximal")
	_copy_bone("Index_Intermediate")
	_copy_bone("Index_Distal")
	_copy_bone("Index_Tip")
	_copy_bone("Middle_Metacarpal")
	_copy_bone("Middle_Proximal")
	_copy_bone("Middle_Intermediate")
	_copy_bone("Middle_Distal")
	_copy_bone("Middle_Tip")
	_copy_bone("Ring_Metacarpal")
	_copy_bone("Ring_Proximal")
	_copy_bone("Ring_Intermediate")
	_copy_bone("Ring_Distal")
	_copy_bone("Ring_Tip")
	_copy_bone("Little_Metacarpal")
	_copy_bone("Little_Proximal")
	_copy_bone("Little_Intermediate")
	_copy_bone("Little_Distal")
	_copy_bone("Little_Tip")

	# Skip if not saving
	if _save_countdown < 0.0:
		return

	# Handle counting down
	_save_countdown -= delta
	if _save_countdown >= 0.0:
		%SaveLabel.text = "%.1f >> pose_%d" % [_save_countdown, _save_index]
		return

	# Save the resources
	ResourceSaver.save(_left_animation, "user://pose_%d_left.tres" % _save_index)
	ResourceSaver.save(_right_animation, "user://pose_%d_right.tres" % _save_index)

	# Advance to the next save slot
	_save_countdown = -1.0
	_save_index += 1
	%SaveLabel.text = "Save: pose_%d" % _save_index


# Copy a named bone to the left and right animations
func _copy_bone(p_name : String) -> void:
	# Get the bone
	var bone := _skeleton.find_bone(p_name + "_L")
	if bone < 0:
		return

	# Construct the animation paths
	var left_path := NodePath(":" + p_name + "_L")
	var right_path := NodePath(":" + p_name + "_R")

	# Construct the animation rotations
	var left_rot := _skeleton.get_bone_pose_rotation(bone)
	var right_rot := Quaternion(left_rot.x, -left_rot.y, -left_rot.z, left_rot.w)

	# Set the tracks in the animation
	_set_track_quaternion(_left_animation, left_path, left_rot)
	_set_track_quaternion(_right_animation, right_path, right_rot)


# Set an animation rotation
func _set_track_quaternion(
	p_animation : Animation,
	p_path : NodePath,
	p_quaternion : Quaternion) -> void:
	# Get (or create) the track
	var track := p_animation.find_track(p_path, Animation.TYPE_ROTATION_3D)
	if track < 0:
		track = p_animation.add_track(Animation.TYPE_ROTATION_3D)
		p_animation.track_set_path(track, p_path)
		var key := p_animation.rotation_track_insert_key(track, 0, p_quaternion)

	# Set the quaternion
	p_animation.track_set_key_value(track, 0, p_quaternion)


# Start XR
func _start_xr() -> void:
	_xr_interface = XRServer.find_interface("OpenXR")
	if _xr_interface and _xr_interface.is_initialized():
		print("OpenXR initialized successfully")

		# Turn off v-sync!
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

		# Change our main viewport to output to the HMD
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialized, please check if your headset is connected")


# Handle triggering save when the user presses the save button
func _on_save_area_area_entered(_area : Area3D):
	_save_countdown = 3.0
