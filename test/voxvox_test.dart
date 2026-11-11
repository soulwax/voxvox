import 'package:test/test.dart';
import 'package:voxvox/voxvox.dart';

void main() {
  group('VoxelCoord & World Spatial Indexing', () {
    test('coordinate translation for positive and negative coords', () {
      final world = VoxelWorld(chunkSize: 16);

      // (0, 0, 0) -> Chunk (0, 0, 0), Local (0, 0, 0)
      expect(world.worldToChunk(0, 0, 0), equals(const ChunkCoord(0, 0, 0)));
      expect(world.worldToLocal(0, 0, 0), equals(const VoxelCoord(0, 0, 0)));

      // (15, 15, 15) -> Chunk (0, 0, 0), Local (15, 15, 15)
      expect(world.worldToChunk(15, 15, 15), equals(const ChunkCoord(0, 0, 0)));
      expect(world.worldToLocal(15, 15, 15), equals(const VoxelCoord(15, 15, 15)));

      // (16, 0, 0) -> Chunk (1, 0, 0), Local (0, 0, 0)
      expect(world.worldToChunk(16, 0, 0), equals(const ChunkCoord(1, 0, 0)));
      expect(world.worldToLocal(16, 0, 0), equals(const VoxelCoord(0, 0, 0)));

      // (-1, -1, -1) -> Chunk (-1, -1, -1), Local (15, 15, 15)
      expect(world.worldToChunk(-1, -1, -1), equals(const ChunkCoord(-1, -1, -1)));
      expect(world.worldToLocal(-1, -1, -1), equals(const VoxelCoord(15, 15, 15)));
    });

    test('setting and getting voxels across chunk borders', () {
      final world = VoxelWorld(chunkSize: 16);
      world.setVoxel(5, 5, 5, 1);
      world.setVoxel(-10, 20, -5, 2);

      expect(world.getVoxel(5, 5, 5), equals(1));
      expect(world.getVoxel(-10, 20, -5), equals(2));
      expect(world.getVoxel(0, 0, 0), equals(0)); // empty air
      expect(world.isSolid(5, 5, 5), isTrue);
      expect(world.isSolid(0, 0, 0), isFalse);
    });
  });

  group('VoxelChunk', () {
    test('nonAirCount and isEmpty tracking', () {
      final chunk = VoxelChunk(chunkSize: 8);
      expect(chunk.isEmpty, isTrue);
      expect(chunk.nonAirCount, 0);

      chunk.setVoxel(2, 3, 4, 1);
      expect(chunk.isEmpty, isFalse);
      expect(chunk.nonAirCount, 1);

      chunk.setVoxel(2, 3, 4, 0);
      expect(chunk.isEmpty, isTrue);
      expect(chunk.nonAirCount, 0);
    });
  });

  group('GreedyMesher', () {
    test('empty chunk produces 0 quads and triangles', () {
      final mesher = GreedyMesher();
      final chunk = VoxelChunk(chunkSize: 16);
      final mesh = mesher.meshChunk(chunk);

      expect(mesh.quadCount, 0);
      expect(mesh.triangleCount, 0);
      expect(mesh.vertexCount, 0);
    });

    test('single isolated voxel produces exactly 6 quads (12 triangles)', () {
      final mesher = GreedyMesher();
      final chunk = VoxelChunk(chunkSize: 16);
      chunk.setVoxel(5, 5, 5, 1);

      final mesh = mesher.meshChunk(chunk);
      expect(mesh.quadCount, 6);
      expect(mesh.triangleCount, 12);
      expect(mesh.vertexCount, 24);
    });

    test('4x4x4 solid block merges into exactly 6 quads (massive polygon reduction)', () {
      final mesher = GreedyMesher();
      final chunk = VoxelChunk(chunkSize: 16);
      chunk.fillRegion(0, 0, 0, 3, 3, 3, 1); // 4x4x4 = 64 solid stone voxels

      final mesh = mesher.meshChunk(chunk);
      // Naive would be 6 faces * 64 voxels = 384 quads or 96 outer quads.
      // Greedy meshing must merge all 6 outer faces into exactly 6 quads!
      expect(mesh.quadCount, 6);
      expect(mesh.triangleCount, 12);
    });
  });

  group('VoxelRaycaster (3D DDA)', () {
    test('ray intersects solid voxel and returns face normal and adjacent voxel', () {
      final world = VoxelWorld(chunkSize: 16);
      // Place a stone block at (10, 0, 0)
      world.setVoxel(10, 0, 0, 1);

      final raycaster = VoxelRaycaster(world);
      // Ray from (0.5, 0.5, 0.5) pointed in +X
      final hit = raycaster.raycast(
        origin: const VoxelVec3(0.5, 0.5, 0.5),
        direction: const VoxelVec3(1.0, 0.0, 0.0),
        maxDistance: 20.0,
      );

      expect(hit, isNotNull);
      expect(hit!.hitVoxel, equals(const VoxelCoord(10, 0, 0)));
      expect(hit.adjacentEmptyVoxel, equals(const VoxelCoord(9, 0, 0)));
      expect(hit.normal.x, closeTo(-1.0, 1e-4));
      expect(hit.distance, closeTo(9.5, 1e-2));
      expect(hit.blockId, equals(1));
    });

    test('ray misses when no solid voxel is in path', () {
      final world = VoxelWorld(chunkSize: 16);
      world.setVoxel(5, 10, 5, 1);

      final raycaster = VoxelRaycaster(world);
      final hit = raycaster.raycast(
        origin: const VoxelVec3(0.0, 0.0, 0.0),
        direction: const VoxelVec3(1.0, 0.0, 0.0),
        maxDistance: 20.0,
      );

      expect(hit, isNull);
    });
  });

  group('VoxelBrush & Terrain Tools', () {
    test('boxFill creates solid region', () {
      final world = VoxelWorld(chunkSize: 16);
      final filled = VoxelBrush.boxFill(
        world,
        min: const VoxelCoord(0, 0, 0),
        max: const VoxelCoord(2, 2, 2),
        blockId: 1,
      );

      expect(filled, 27); // 3x3x3 = 27
      expect(world.getVoxel(1, 1, 1), equals(1));
      expect(world.getVoxel(3, 3, 3), equals(0));
    });

    test('sphereCarve carves spherical cavity', () {
      final world = VoxelWorld(chunkSize: 16);
      VoxelBrush.boxFill(
        world,
        min: const VoxelCoord(0, 0, 0),
        max: const VoxelCoord(10, 10, 10),
        blockId: 1,
      );

      expect(world.getVoxel(5, 5, 5), equals(1));

      // Carve sphere of radius 3 at (5, 5, 5)
      final carved = VoxelBrush.sphereCarve(
        world,
        center: const VoxelCoord(5, 5, 5),
        radius: 2.5,
      );

      expect(carved, greaterThan(0));
      expect(world.getVoxel(5, 5, 5), equals(0)); // carved center is now air
      expect(world.getVoxel(0, 0, 0), equals(1)); // corner unaffected
    });

    test('generateHeightmapTerrain creates tiered layers', () {
      final world = VoxelWorld(chunkSize: 16);
      VoxelBrush.generateHeightmapTerrain(
        world,
        minX: 0,
        maxX: 4,
        minZ: 0,
        maxZ: 4,
        heightFunction: (x, z) => 6.0,
      );

      // Top block (y = 6) should be grass (id: 3)
      expect(world.getVoxel(2, 6, 2), equals(3));
      // Subsurface block (y = 5) should be dirt (id: 2)
      expect(world.getVoxel(2, 5, 2), equals(2));
      // Deep block (y = 1) should be stone (id: 1)
      expect(world.getVoxel(2, 1, 2), equals(1));
      // Above terrain (y = 7) should be air (id: 0)
      expect(world.getVoxel(2, 7, 2), equals(0));
    });
  });
}
