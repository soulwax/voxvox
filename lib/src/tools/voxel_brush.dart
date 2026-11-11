import 'dart:math' as math;
import '../math/voxel_coord.dart';
import '../voxels/voxel_world.dart';

/// Tools for modifying, carving, building, and generating voxel geometry.
class VoxelBrush {
  /// Carves a sphere out of the world (replaces solid blocks with [replaceWith], default 0 = air).
  static int sphereCarve(
    VoxelWorld world, {
    required VoxelCoord center,
    required double radius,
    int replaceWith = 0,
  }) {
    int modified = 0;
    final rCeil = radius.ceil();
    final rSq = radius * radius;

    for (int x = -rCeil; x <= rCeil; x++) {
      for (int y = -rCeil; y <= rCeil; y++) {
        for (int z = -rCeil; z <= rCeil; z++) {
          if (x * x + y * y + z * z <= rSq) {
            final wx = center.x + x;
            final wy = center.y + y;
            final wz = center.z + z;
            final current = world.getVoxel(wx, wy, wz);
            if (current != replaceWith) {
              world.setVoxel(wx, wy, wz, replaceWith);
              modified++;
            }
          }
        }
      }
    }
    return modified;
  }

  /// Fills a spherical volume with [blockId].
  static int sphereFill(
    VoxelWorld world, {
    required VoxelCoord center,
    required double radius,
    required int blockId,
  }) {
    int modified = 0;
    final rCeil = radius.ceil();
    final rSq = radius * radius;

    for (int x = -rCeil; x <= rCeil; x++) {
      for (int y = -rCeil; y <= rCeil; y++) {
        for (int z = -rCeil; z <= rCeil; z++) {
          if (x * x + y * y + z * z <= rSq) {
            final wx = center.x + x;
            final wy = center.y + y;
            final wz = center.z + z;
            world.setVoxel(wx, wy, wz, blockId);
            modified++;
          }
        }
      }
    }
    return modified;
  }

  /// Fills an axis-aligned bounding box with [blockId].
  static int boxFill(
    VoxelWorld world, {
    required VoxelCoord min,
    required VoxelCoord max,
    required int blockId,
  }) {
    int count = 0;
    final minX = math.min(min.x, max.x);
    final maxX = math.max(min.x, max.x);
    final minY = math.min(min.y, max.y);
    final maxY = math.max(min.y, max.y);
    final minZ = math.min(min.z, max.z);
    final maxZ = math.max(min.z, max.z);

    for (int x = minX; x <= maxX; x++) {
      for (int y = minY; y <= maxY; y++) {
        for (int z = minZ; z <= maxZ; z++) {
          world.setVoxel(x, y, z, blockId);
          count++;
        }
      }
    }
    return count;
  }

  /// Generates a heightmap-based voxel terrain.
  static void generateHeightmapTerrain(
    VoxelWorld world, {
    required int minX,
    required int maxX,
    required int minZ,
    required int maxZ,
    required double Function(double x, double z) heightFunction,
    int grassBlockId = 3,
    int dirtBlockId = 2,
    int stoneBlockId = 1,
    int dirtDepth = 3,
  }) {
    for (int x = minX; x <= maxX; x++) {
      for (int z = minZ; z <= maxZ; z++) {
        final height = heightFunction(x.toDouble(), z.toDouble()).round();
        for (int y = 0; y <= height; y++) {
          int block;
          if (y == height) {
            block = grassBlockId;
          } else if (y >= height - dirtDepth) {
            block = dirtBlockId;
          } else {
            block = stoneBlockId;
          }
          world.setVoxel(x, y, z, block);
        }
      }
    }
  }
}
