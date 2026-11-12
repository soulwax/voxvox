<p align="center">
  <img src="assets/logo.svg" width="88" alt="voxvox logo"/>
</p>

# voxvox

Pure Dart high-performance voxel engine library featuring chunk storage, greedy meshing with vertex ambient occlusion, 3D Amanatides-Woo DDA raymarching, and destructible terrain tools.

## Features

- **Cubic Voxel Chunks:** Flat, zero-overhead memory footprint (`Uint16List`) with spatial indexing and chunk coordination.
- **Voxel World:** Spatial hashing multi-chunk container with negative and positive world-space coordinate translation.
- **Greedy Meshing Algorithm:** Reduces polygon count by up to 90%+ compared to naive per-voxel cube rendering by merging coplanar faces into minimal rectangular quads.
- **Smooth Vertex Ambient Occlusion:** 4-level vertex corner occlusion baked directly into vertex colors.
- **Fast 3D DDA Raycaster:** Exact grid traversal (Amanatides-Woo algorithm) finding raycast hit voxel, face normal, and adjacent empty block for block placement.
- **Destructible Terrain Tools:** Sphere carving, box fills, and procedural heightmap generation.
