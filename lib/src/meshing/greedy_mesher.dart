import '../math/voxel_coord.dart';
import '../voxels/voxel_block.dart';
import '../voxels/voxel_chunk.dart';
import '../voxels/voxel_world.dart';
import 'voxel_mesh.dart';

/// One face element in the 2D sweep mask for greedy meshing.
class _MaskCell {
  final int blockId;
  final int faceDir; // +1 or -1

  const _MaskCell(this.blockId, this.faceDir);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MaskCell && runtimeType == other.runtimeType && blockId == other.blockId && faceDir == other.faceDir;

  @override
  int get hashCode => Object.hash(blockId, faceDir);
}

/// Generates optimized polygon meshes from voxel volumes using the greedy meshing algorithm.
class GreedyMesher {
  final VoxelBlockPalette palette;

  GreedyMesher([VoxelBlockPalette? palette]) : palette = palette ?? VoxelBlockPalette();

  /// Meshes a single standalone chunk (out-of-bounds voxels treated as air).
  VoxelMesh meshChunk(VoxelChunk chunk) {
    final mesh = VoxelMesh();
    if (chunk.isEmpty) return mesh;

    _generateGreedyMesh(
      chunkSize: chunk.chunkSize,
      getVoxel: (x, y, z) => chunk.getVoxel(x, y, z),
      chunkOrigin: VoxelVec3.zero,
      mesh: mesh,
    );
    return mesh;
  }

  /// Meshes a chunk within a [world] context, properly sampling neighboring chunks at borders.
  VoxelMesh meshWorldChunk(VoxelWorld world, ChunkCoord coord) {
    final mesh = VoxelMesh();
    final chunk = world.getChunk(coord);
    if (chunk == null || chunk.isEmpty) return mesh;

    final cs = world.chunkSize;
    final ox = coord.cx * cs.toDouble();
    final oy = coord.cy * cs.toDouble();
    final oz = coord.cz * cs.toDouble();

    final wx0 = coord.cx * cs;
    final wy0 = coord.cy * cs;
    final wz0 = coord.cz * cs;

    _generateGreedyMesh(
      chunkSize: cs,
      getVoxel: (x, y, z) => world.getVoxel(wx0 + x, wy0 + y, wz0 + z),
      chunkOrigin: VoxelVec3(ox, oy, oz),
      mesh: mesh,
    );
    return mesh;
  }

  void _generateGreedyMesh({
    required int chunkSize,
    required int Function(int x, int y, int z) getVoxel,
    required VoxelVec3 chunkOrigin,
    required VoxelMesh mesh,
  }) {
    // 3 axes: 0 = X, 1 = Y, 2 = Z
    for (int d = 0; d < 3; d++) {
      final u = (d + 1) % 3;
      final v = (d + 2) % 3;

      final x = [0, 0, 0];
      final q = [0, 0, 0];
      q[d] = 1;

      final mask = List<_MaskCell?>.filled(chunkSize * chunkSize, null);

      // Sweep slices along dimension d
      for (x[d] = -1; x[d] < chunkSize;) {
        int n = 0;

        // Populate mask for this slice
        for (x[v] = 0; x[v] < chunkSize; x[v]++) {
          for (x[u] = 0; x[u] < chunkSize; x[u]++) {
            final aId = (x[d] >= 0) ? getVoxel(x[0], x[1], x[2]) : 0;
            final bId = (x[d] < chunkSize - 1) ? getVoxel(x[0] + q[0], x[1] + q[1], x[2] + q[2]) : 0;

            final aOpaque = palette.isOpaque(aId);
            final bOpaque = palette.isOpaque(bId);

            if (aOpaque == bOpaque) {
              mask[n++] = null;
            } else if (aOpaque) {
              mask[n++] = _MaskCell(aId, 1);
            } else {
              mask[n++] = _MaskCell(bId, -1);
            }
          }
        }

        x[d]++;

        // Generate greedy quads from mask
        n = 0;
        for (int j = 0; j < chunkSize; j++) {
          for (int i = 0; i < chunkSize;) {
            final cell = mask[n];
            if (cell != null) {
              // Compute width
              int w = 1;
              while (i + w < chunkSize && mask[n + w] == cell) {
                w++;
              }

              // Compute height
              int h = 1;
              bool canExtend = true;
              while (j + h < chunkSize && canExtend) {
                for (int k = 0; k < w; k++) {
                  if (mask[n + k + h * chunkSize] != cell) {
                    canExtend = false;
                    break;
                  }
                }
                if (canExtend) h++;
              }

              // Emit quad
              x[u] = i;
              x[v] = j;

              final du = [0, 0, 0];
              final dv = [0, 0, 0];
              du[u] = w;
              dv[v] = h;

              final normalVec = [0.0, 0.0, 0.0];
              normalVec[d] = cell.faceDir.toDouble();

              final p0 = VoxelVec3(
                chunkOrigin.x + x[0],
                chunkOrigin.y + x[1],
                chunkOrigin.z + x[2],
              );

              final p1 = VoxelVec3(p0.x + du[0], p0.y + du[1], p0.z + du[2]);
              final p2 = VoxelVec3(p0.x + du[0] + dv[0], p0.y + du[1] + dv[1], p0.z + du[2] + dv[2]);
              final p3 = VoxelVec3(p0.x + dv[0], p0.y + dv[1], p0.z + dv[2]);

              final block = palette.getBlock(cell.blockId);
              final norm = VoxelVec3(normalVec[0], normalVec[1], normalVec[2]);

              // Calculate ambient occlusion for vertices
              final ao = _calcQuadAo(x[0], x[1], x[2], du, dv, q, cell.faceDir, getVoxel);

              if (cell.faceDir > 0) {
                mesh.addQuad(
                  v0: p0,
                  v1: p1,
                  v2: p2,
                  v3: p3,
                  normal: norm,
                  color: block.color,
                  uSpan: w.toDouble(),
                  vSpan: h.toDouble(),
                  aoLevels: ao,
                );
              } else {
                mesh.addQuad(
                  v0: p0,
                  v1: p3,
                  v2: p2,
                  v3: p1,
                  normal: norm,
                  color: block.color,
                  uSpan: w.toDouble(),
                  vSpan: h.toDouble(),
                  aoLevels: [ao[0], ao[3], ao[2], ao[1]],
                );
              }

              // Clear mask for spanned quad
              for (int l = 0; l < h; l++) {
                for (int k = 0; k < w; k++) {
                  mask[n + k + l * chunkSize] = null;
                }
              }

              i += w;
              n += w;
            } else {
              i++;
              n++;
            }
          }
        }
      }
    }
  }

  List<double> _calcQuadAo(
    int x,
    int y,
    int z,
    List<int> du,
    List<int> dv,
    List<int> q,
    int faceDir,
    int Function(int x, int y, int z) getVoxel,
  ) {
    // Standard vertex AO based on adjacent solid blocks
    double vertexAo(int vx, int vy, int vz, int s1x, int s1y, int s1z, int s2x, int s2y, int s2z, int cx, int cy, int cz) {
      final s1 = palette.isOpaque(getVoxel(vx + s1x, vy + s1y, vz + s1z)) ? 1 : 0;
      final s2 = palette.isOpaque(getVoxel(vx + s2x, vy + s2y, vz + s2z)) ? 1 : 0;
      final c = palette.isOpaque(getVoxel(vx + cx, vy + cy, vz + cz)) ? 1 : 0;
      if (s1 == 1 && s2 == 1) return 0.35;
      final count = 3 - (s1 + s2 + c);
      switch (count) {
        case 3: return 1.0;
        case 2: return 0.8;
        case 1: return 0.55;
        default: return 0.35;
      }
    }

    final fx = q[0] * faceDir;
    final fy = q[1] * faceDir;
    final fz = q[2] * faceDir;

    final ao0 = vertexAo(x, y, z, -du[0], -du[1], -du[2], -dv[0], -dv[1], -dv[2], -du[0] - dv[0] + fx, -du[1] - dv[1] + fy, -du[2] - dv[2] + fz);
    final ao1 = vertexAo(x + du[0], y + du[1], z + du[2], du[0], du[1], du[2], -dv[0], -dv[1], -dv[2], du[0] - dv[0] + fx, du[1] - dv[1] + fy, du[2] - dv[2] + fz);
    final ao2 = vertexAo(x + du[0] + dv[0], y + du[1] + dv[1], z + du[2] + dv[2], du[0], du[1], du[2], dv[0], dv[1], dv[2], du[0] + dv[0] + fx, du[1] + dv[1] + fy, du[2] + dv[2] + fz);
    final ao3 = vertexAo(x + dv[0], y + dv[1], z + dv[2], -du[0], -du[1], -du[2], dv[0], dv[1], dv[2], -du[0] + dv[0] + fx, -du[1] + dv[1] + fy, -du[2] + dv[2] + fz);

    return [ao0, ao1, ao2, ao3];
  }
}
