extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	_add_bones.call_deferred()

func _add_bones() -> void:
	var mesh_resource := CylinderMesh.new()
	mesh_resource.rings = 1
	mesh_resource.radial_segments = 4
	mesh_resource.bottom_radius = 0.004
	mesh_resource.top_radius = 0.002
	mesh_resource.height = 0.02
	
	var skeleton : Skeleton3D = get_parent()
	var bones = skeleton.get_bone_count();
	for b in bones:
		var bone_name := skeleton.get_bone_name(b)
		var attachment := BoneAttachment3D.new()
		skeleton.add_child(attachment)
		attachment.bone_name = bone_name

		var mesh := MeshInstance3D.new()
		mesh.mesh = mesh_resource
		mesh.rotate_x(-PI/2)
		mesh.position.z = -0.01
		attachment.add_child(mesh)
