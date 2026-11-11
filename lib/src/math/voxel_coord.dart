import 'dart:math' as math;

/// 3D integer coordinate for voxel positions.
class VoxelCoord {
  final int x;
  final int y;
  final int z;

  const VoxelCoord(this.x, this.y, this.z);

  static const VoxelCoord zero = VoxelCoord(0, 0, 0);

  VoxelCoord operator +(VoxelCoord other) => VoxelCoord(x + other.x, y + other.y, z + other.z);
  VoxelCoord operator -(VoxelCoord other) => VoxelCoord(x - other.x, y - other.y, z - other.z);
  VoxelCoord operator -() => VoxelCoord(-x, -y, -z);

  double distanceTo(VoxelCoord other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final dz = z - other.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoxelCoord && runtimeType == other.runtimeType && x == other.x && y == other.y && z == other.z;

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => 'VoxelCoord($x, $y, $z)';
}

/// Coordinate of a chunk in the voxel world grid.
class ChunkCoord {
  final int cx;
  final int cy;
  final int cz;

  const ChunkCoord(this.cx, this.cy, this.cz);

  static const ChunkCoord zero = ChunkCoord(0, 0, 0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChunkCoord && runtimeType == other.runtimeType && cx == other.cx && cy == other.cy && cz == other.cz;

  @override
  int get hashCode => Object.hash(cx, cy, cz);

  @override
  String toString() => 'ChunkCoord($cx, $cy, $cz)';
}

/// Continuous 3D vector for voxel world positions and raymarching.
class VoxelVec3 {
  final double x;
  final double y;
  final double z;

  const VoxelVec3(this.x, this.y, this.z);

  static const VoxelVec3 zero = VoxelVec3(0.0, 0.0, 0.0);

  VoxelVec3 operator +(VoxelVec3 other) => VoxelVec3(x + other.x, y + other.y, z + other.z);
  VoxelVec3 operator -(VoxelVec3 other) => VoxelVec3(x - other.x, y - other.y, z - other.z);
  VoxelVec3 operator -() => VoxelVec3(-x, -y, -z);
  VoxelVec3 operator *(double scalar) => VoxelVec3(x * scalar, y * scalar, z * scalar);
  VoxelVec3 operator /(double scalar) => VoxelVec3(x / scalar, y / scalar, z / scalar);

  double get lengthSquared => x * x + y * y + z * z;
  double get length => math.sqrt(lengthSquared);

  VoxelVec3 get normalized {
    final len = length;
    if (len < 1e-12) return VoxelVec3.zero;
    return this / len;
  }

  @override
  String toString() => 'VoxelVec3(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}, ${z.toStringAsFixed(2)})';
}
