import 'dart:typed_data';
import '../math/voxel_coord.dart';

/// 3D cubic voxel chunk stored in a flat contiguous array.
class VoxelChunk {
  final int chunkSize;
  final ChunkCoord coord;
  late final Uint16List _data;

  bool isModified = true;
  int _nonAirCount = 0;

  VoxelChunk({
    this.chunkSize = 16,
    this.coord = ChunkCoord.zero,
  }) {
    _data = Uint16List(chunkSize * chunkSize * chunkSize);
  }

  /// Whether the chunk contains any solid or non-air voxels.
  bool get isEmpty => _nonAirCount == 0;

  /// Number of non-air voxels in this chunk.
  int get nonAirCount => _nonAirCount;

  @pragma('vm:prefer-inline')
  int _index(int x, int y, int z) => (x * chunkSize + y) * chunkSize + z;

  @pragma('vm:prefer-inline')
  bool inBounds(int x, int y, int z) =>
      x >= 0 && x < chunkSize && y >= 0 && y < chunkSize && z >= 0 && z < chunkSize;

  /// Gets the block ID at local chunk coordinates (x, y, z).
  int getVoxel(int x, int y, int z) {
    if (!inBounds(x, y, z)) return 0;
    return _data[_index(x, y, z)];
  }

  /// Sets the block ID at local chunk coordinates (x, y, z).
  void setVoxel(int x, int y, int z, int blockId) {
    if (!inBounds(x, y, z)) return;
    final idx = _index(x, y, z);
    final prev = _data[idx];
    if (prev == blockId) return;

    if (prev == 0 && blockId != 0) {
      _nonAirCount++;
    } else if (prev != 0 && blockId == 0) {
      _nonAirCount--;
    }

    _data[idx] = blockId;
    isModified = true;
  }

  /// Fills the entire chunk with a single block ID.
  void fill(int blockId) {
    _data.fillRange(0, _data.length, blockId);
    _nonAirCount = (blockId == 0) ? 0 : _data.length;
    isModified = true;
  }

  /// Fills an axis-aligned box within local coordinates.
  void fillRegion(int x0, int y0, int z0, int x1, int y1, int z1, int blockId) {
    final minX = x0.clamp(0, chunkSize - 1);
    final maxX = x1.clamp(0, chunkSize - 1);
    final minY = y0.clamp(0, chunkSize - 1);
    final maxY = y1.clamp(0, chunkSize - 1);
    final minZ = z0.clamp(0, chunkSize - 1);
    final maxZ = z1.clamp(0, chunkSize - 1);

    for (int x = minX; x <= maxX; x++) {
      for (int y = minY; y <= maxY; y++) {
        for (int z = minZ; z <= maxZ; z++) {
          setVoxel(x, y, z, blockId);
        }
      }
    }
  }
}
