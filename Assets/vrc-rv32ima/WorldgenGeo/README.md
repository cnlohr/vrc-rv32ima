# Geometry Output Device

## Genearal Layout

Assuming the top row of the system memory texture is filled with CPU cores, the next row below that is the geometry descriptor layer.

This tool facilitates 512x objects, each with 1,024 pieces of geometry. The `draw descriptor` contains a sort of "geometry shard" which could be merged together and point at one object descriptor.

An Object Descriptor provides a logical "entity."

## 

### Draw Descriptor
```
.r = asuint bit mask of the following:
	0..1023 : Number of triangles to output.
	1024 : This is active.
	2048 : "4x3 model matrix" is actually just a position/scale/quaternion.
	4096 : Future: If 1, use float in object descriptor.
	
.g = asuint
	Pointer to the object descriptor describing this object.

.b = asuint
	Pointer to the raw geometry describing this object.

.a = reserved
```

### Object Descriptor

Object Descriptors MAY cross system-memory-line boundaries.

```
In left-to-right order:

[General Desciptor]
[Color Field (diffuse)]
[Color Field (emit)]
[Reserved]

[4x3 Model Matrix]
```


