extends RefCounted
## Small authored mesh library: bevel highlights without runtime CSG or plugins.
static func bevel_box(size: Vector3, bevel := 0.02) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var half := size * 0.5
    bevel = minf(bevel, minf(half.x,minf(half.y,half.z))*0.7)
    var inner := half - Vector3.ONE*bevel
    for face in range(6):
        var axis: int = face / 2
        var sign_value := 1.0 if face % 2 == 0 else -1.0
        var n := Vector3.ZERO
        n[axis] = sign_value
        var u := Vector3.ZERO
        u[(axis+1)%3] = 1.0
        var v := n.cross(u)
        var hu: float = half[(axis+1)%3]
        var hv: float = half[(axis+2)%3]
        var us := [-hu, -hu+bevel, 0.0, hu-bevel, hu]
        var vs := [-hv, -hv+bevel, 0.0, hv-bevel, hv]
        for x in range(4):
            for y in range(4):
                for corner in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(1,0)]:
                    var raw: Vector3 = n*half[axis]+u*us[x+corner.x]+v*vs[y+corner.y]
                    var core := raw.clamp(-inner,inner)
                    var normal := (raw-core).normalized()
                    st.set_normal(normal)
                    st.set_uv(Vector2(float(x+corner.x)/4.0,float(y+corner.y)/4.0))
                    st.add_vertex(core+normal*bevel)
    st.generate_tangents()
    return st.commit()

static func part(parent: Node3D, shape: Mesh, pos: Vector3, mat: Material, scale_xyz:=Vector3.ONE, rot:=Vector3.ZERO) -> MeshInstance3D:
    var node:=MeshInstance3D.new()
    node.mesh=shape
    node.position=pos
    node.material_override=mat
    node.scale=scale_xyz
    node.rotation=rot
    parent.add_child(node)
    return node

static func box(parent:Node3D,pos:Vector3,size:Vector3,mat:Material,bevel:=0.015,rot:=Vector3.ZERO)->MeshInstance3D:
    return part(parent,bevel_box(size,bevel),pos,mat,Vector3.ONE,rot)

static func ellipsoid(parent:Node3D,pos:Vector3,size:Vector3,mat:Material)->MeshInstance3D:
    var shape:=SphereMesh.new()
    shape.radius=0.5
    shape.height=1.0
    shape.radial_segments=16
    shape.rings=10
    return part(parent,shape,pos,mat,size)

static func rod(parent:Node3D,a:Vector3,b:Vector3,radius:float,mat:Material,top:float=-1.0)->MeshInstance3D:
    var shape:=CylinderMesh.new()
    shape.bottom_radius=radius
    shape.top_radius=radius if top<0 else top
    shape.height=a.distance_to(b)
    shape.radial_segments=16
    var item:=part(parent,shape,(a+b)*0.5,mat)
    var direction:Vector3=(b-a).normalized()
    var axis:=Vector3.UP.cross(direction)
    if axis.length()>0.001:item.quaternion=Quaternion(axis.normalized(),acos(clampf(Vector3.UP.dot(direction),-1,1)))
    elif direction.y<0:item.rotation.x=PI
    return item

static func batch_static(parent: Node3D, keep: Array = []) -> void:
    var groups: Dictionary = {}
    for child in parent.get_children():
        if child is MeshInstance3D and not child in keep:
            var mat: Material = child.material_override
            if not groups.has(mat): groups[mat] = []
            groups[mat].append(child)
    for mat in groups:
        var st := SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        for child in groups[mat]:
            for surface in range(child.mesh.get_surface_count()):
                st.append_from(child.mesh, surface, child.transform)
        var result := MeshInstance3D.new()
        result.mesh = st.commit()
        result.material_override = mat
        for child in groups[mat]:
            parent.remove_child(child)
            child.free()
        parent.add_child(result)
