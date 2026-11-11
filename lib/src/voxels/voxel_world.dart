import '../math/voxel_coord.dart';
import 'voxel_block.dart';
import 'voxel_chunk.dart';

/// Multi-chunk voxel world with global 3D integer coordinate spatial indexing.
class VoxelWorld {
  final int chunkSize;
  final VoxelBlockPalette palette;
  final Map<ChunkCoord, VoxelChunk> _chunks = {};

  VoxelWorld({
    this.chunkSize = 16,
    VoxelBlockPalette? palette,
  }) : palette = palette ?? VoxelBlockPalette();

  /// Converts world voxel coordinates to the corresponding chunk coordinate.
  ChunkCoord worldToChunk(int wx, int wy, int wz) {
    return ChunkCoord(
      (wx / chunkSize).floor(),
      (wy / chunkSize).floor(),
      (wz / chunkSize).floor(),
    );
  }

  /// Converts world voxel coordinates to local chunk coordinates [0, chunkSize - 1].
  VoxelCoord worldToLocal(int wx, int wy, int wz) {
    final cx = (wx / chunkSize).floor();
    final cy = (wy / chunkSize).floor();
    final cz = (wz / chunkSize).floor();
    return VoxelCoord(
      wx - cx * chunkSize,
      wy - cy * chunkSize,
      wz - cz * chunkSize,
    );
  }

  /// Retrieves an existing chunk or returns null if not loaded.
  VoxelChunk? getChunk(ChunkCoord coord) => _chunks[coord];

  /// Retrieves or allocates a new chunk at [coord].
  VoxelChunk getOrCreateChunk(ChunkCoord coord) {
    return _chunks.putIfAbsent(coord, () => VoxelChunk(chunkSize: chunkSize, coord: coord));
  }

  /// Gets the block ID at global world coordinates.
  int getVoxel(int wx, int wy, int wz) {
    final cCoord = worldToChunk(wx, wy, wz);
    final chunk = _chunks[cCoord];
    if (chunk == null) return 0;
    final lCoord = worldToLocal(wx, wy, wz);
    return chunk.getVoxel(lCoord.x, lCoord.y, lCoord.z);
  }

  /// Sets the block ID at global world coordinates, creating the chunk if necessary.
  void setVoxel(int wx, int wy, int wz, int blockId) {
    final cCoord = worldToChunk(wx, wy, wz);
    final chunk = getOrCreateChunk(cCoord);
    final lCoord = worldToLocal(wx, wy, wz);
    chunk.setVoxel(lCoord.x, lCoord.y, lCoord.z, blockId);
  }

  /// Whether the block at global coordinates is solid.
  bool isSolid(int wx, int wy, int wz) {
    final id = getVoxel(wx, wy, wz);
    return palette.isSolid(id);
  }

  /// Whether the block at global coordinates is opaque.
  bool isOpaque(int wx, int wy, int wz) {
    final id = getVoxel(wx, wy, wz);
    return palette.isOpaque(id);
  }

  /// All active chunks currently in this world.
  Iterable<VoxelChunk> get chunks => _chunks.values;

  /// Number of active chunks.
  int get chunkCount => _chunks.length;

  /// Removes and unloads a chunk.
  void removeChunk(ChunkCoord coord) => _chunks.remove(coord);

  /// Clears all chunks.
  void clear() => _chunks.clear();
}
