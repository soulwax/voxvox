import '../math/voxel_coord.dart';

/// Mesh geometry generated from voxel chunks.
class VoxelMesh {
  final List<double> positions = [];
  final List<double> normals = [];
  final List<double> uvs = [];
  final List<int> colors = [];
  final List<int> indices = [];

  int get vertexCount => positions.length ~/ 3;
  int get triangleCount => indices.length ~/ 3;
  int get quadCount => indices.length ~/ 6;

  void clear() {
    positions.clear();
    normals.clear();
    uvs.clear();
    colors.clear();
    indices.clear();
  }

  /// Appends a quad defined by 4 vertices in counter-clockwise order.
  void addQuad({
    required VoxelVec3 v0,
    required VoxelVec3 v1,
    required VoxelVec3 v2,
    required VoxelVec3 v3,
    required VoxelVec3 normal,
    required int color,
    double uSpan = 1.0,
    double vSpan = 1.0,
    List<double>? aoLevels, // 4 values in [0.0, 1.0]
  }) {
    final baseIndex = vertexCount;

    final verts = [v0, v1, v2, v3];
    final uvsList = [
      0.0, 0.0,
      uSpan, 0.0,
      uSpan, vSpan,
      0.0, vSpan,
    ];

    for (int i = 0; i < 4; i++) {
      final v = verts[i];
      positions.addAll([v.x, v.y, v.z]);
      normals.addAll([normal.x, normal.y, normal.z]);
      uvs.addAll([uvsList[i * 2], uvsList[i * 2 + 1]]);

      final ao = (aoLevels != null && aoLevels.length > i) ? aoLevels[i] : 1.0;
      final c = _applyAo(color, ao);
      colors.add(c);
    }

    // Two triangles per quad (CCW): (0, 1, 2) and (0, 2, 3)
    indices.addAll([
      baseIndex,
      baseIndex + 1,
      baseIndex + 2,
      baseIndex,
      baseIndex + 2,
      baseIndex + 3,
    ]);
  }

  static int _applyAo(int argb, double ao) {
    final a = (argb >> 24) & 0xFF;
    final r = (((argb >> 16) & 0xFF) * ao).round().clamp(0, 255);
    final g = (((argb >> 8) & 0xFF) * ao).round().clamp(0, 255);
    final b = ((argb & 0xFF) * ao).round().clamp(0, 255);
    return (a << 24) | (r << 16) | (g << 8) | b;
  }
}
