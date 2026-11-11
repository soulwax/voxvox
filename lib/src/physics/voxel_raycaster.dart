import '../math/voxel_coord.dart';
import '../voxels/voxel_world.dart';

/// Information about a voxel raycast intersection.
class VoxelRaycastHit {
  /// Coordinate of the solid voxel that was hit.
  final VoxelCoord hitVoxel;

  /// Empty/air voxel adjacent to the hit face (ideal for placing new blocks).
  final VoxelCoord adjacentEmptyVoxel;

  /// Surface normal vector of the hit voxel face.
  final VoxelVec3 normal;

  /// Distance along the ray from origin to intersection point.
  final double distance;

  /// Block ID of the hit voxel.
  final int blockId;

  const VoxelRaycastHit({
    required this.hitVoxel,
    required this.adjacentEmptyVoxel,
    required this.normal,
    required this.distance,
    required this.blockId,
  });

  @override
  String toString() => 'VoxelRaycastHit(voxel: $hitVoxel, normal: $normal, distance: ${distance.toStringAsFixed(2)})';
}

/// Fast 3D DDA (Amanatides-Woo) raycaster for voxel grids.
class VoxelRaycaster {
  final VoxelWorld world;

  const VoxelRaycaster(this.world);

  /// Performs a 3D DDA raycast through the voxel world.
  VoxelRaycastHit? raycast({
    required VoxelVec3 origin,
    required VoxelVec3 direction,
    double maxDistance = 64.0,
  }) {
    final dir = direction.normalized;
    if (dir.lengthSquared < 1e-8) return null;

    int x = origin.x.floor();
    int y = origin.y.floor();
    int z = origin.z.floor();

    final stepX = dir.x > 0 ? 1 : (dir.x < 0 ? -1 : 0);
    final stepY = dir.y > 0 ? 1 : (dir.y < 0 ? -1 : 0);
    final stepZ = dir.z > 0 ? 1 : (dir.z < 0 ? -1 : 0);

    final tDeltaX = dir.x != 0 ? (1.0 / dir.x).abs() : double.infinity;
    final tDeltaY = dir.y != 0 ? (1.0 / dir.y).abs() : double.infinity;
    final tDeltaZ = dir.z != 0 ? (1.0 / dir.z).abs() : double.infinity;

    double tMaxX = dir.x > 0 ? ((x + 1) - origin.x) * tDeltaX : (origin.x - x) * tDeltaX;
    double tMaxY = dir.y > 0 ? ((y + 1) - origin.y) * tDeltaY : (origin.y - y) * tDeltaY;
    double tMaxZ = dir.z > 0 ? ((z + 1) - origin.z) * tDeltaZ : (origin.z - z) * tDeltaZ;

    // Check if origin voxel itself is solid
    final initialBlock = world.getVoxel(x, y, z);
    if (world.palette.isSolid(initialBlock)) {
      return VoxelRaycastHit(
        hitVoxel: VoxelCoord(x, y, z),
        adjacentEmptyVoxel: VoxelCoord(x, y, z),
        normal: -dir,
        distance: 0.0,
        blockId: initialBlock,
      );
    }

    double currentDist = 0.0;
    int normalX = 0;
    int normalY = 0;
    int normalZ = 0;

    int prevX = x;
    int prevY = y;
    int prevZ = z;

    while (currentDist <= maxDistance) {
      prevX = x;
      prevY = y;
      prevZ = z;

      if (tMaxX < tMaxY) {
        if (tMaxX < tMaxZ) {
          x += stepX;
          currentDist = tMaxX;
          tMaxX += tDeltaX;
          normalX = -stepX;
          normalY = 0;
          normalZ = 0;
        } else {
          z += stepZ;
          currentDist = tMaxZ;
          tMaxZ += tDeltaZ;
          normalX = 0;
          normalY = 0;
          normalZ = -stepZ;
        }
      } else {
        if (tMaxY < tMaxZ) {
          y += stepY;
          currentDist = tMaxY;
          tMaxY += tDeltaY;
          normalX = 0;
          normalY = -stepY;
          normalZ = 0;
        } else {
          z += stepZ;
          currentDist = tMaxZ;
          tMaxZ += tDeltaZ;
          normalX = 0;
          normalY = 0;
          normalZ = -stepZ;
        }
      }

      if (currentDist > maxDistance) break;

      final blockId = world.getVoxel(x, y, z);
      if (world.palette.isSolid(blockId)) {
        return VoxelRaycastHit(
          hitVoxel: VoxelCoord(x, y, z),
          adjacentEmptyVoxel: VoxelCoord(prevX, prevY, prevZ),
          normal: VoxelVec3(normalX.toDouble(), normalY.toDouble(), normalZ.toDouble()),
          distance: currentDist,
          blockId: blockId,
        );
      }
    }

    return null;
  }
}
