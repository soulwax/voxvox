/// Definition and rendering properties of a voxel block type.
class VoxelBlock {
  final int id;
  final String name;
  final bool isSolid;
  final bool isOpaque;
  final int color;

  const VoxelBlock({
    required this.id,
    required this.name,
    this.isSolid = true,
    this.isOpaque = true,
    this.color = 0xFFFFFFFF,
  });

  static const VoxelBlock air = VoxelBlock(
    id: 0,
    name: 'Air',
    isSolid: false,
    isOpaque: false,
    color: 0x00000000,
  );

  static const VoxelBlock stone = VoxelBlock(
    id: 1,
    name: 'Stone',
    color: 0xFF888888,
  );

  static const VoxelBlock dirt = VoxelBlock(
    id: 2,
    name: 'Dirt',
    color: 0xFF8B5A2B,
  );

  static const VoxelBlock grass = VoxelBlock(
    id: 3,
    name: 'Grass',
    color: 0xFF4CAF50,
  );

  static const VoxelBlock wood = VoxelBlock(
    id: 4,
    name: 'Wood',
    color: 0xFF5D4037,
  );

  static const VoxelBlock leaves = VoxelBlock(
    id: 5,
    name: 'Leaves',
    color: 0xFF388E3C,
  );

  static const VoxelBlock sand = VoxelBlock(
    id: 6,
    name: 'Sand',
    color: 0xFFE0C068,
  );

  static const VoxelBlock water = VoxelBlock(
    id: 7,
    name: 'Water',
    isSolid: false,
    isOpaque: false,
    color: 0x882196F3,
  );
}

/// Registry mapping block IDs to their block definitions.
class VoxelBlockPalette {
  final Map<int, VoxelBlock> _blocks = {};

  VoxelBlockPalette() {
    register(VoxelBlock.air);
    register(VoxelBlock.stone);
    register(VoxelBlock.dirt);
    register(VoxelBlock.grass);
    register(VoxelBlock.wood);
    register(VoxelBlock.leaves);
    register(VoxelBlock.sand);
    register(VoxelBlock.water);
  }

  void register(VoxelBlock block) {
    _blocks[block.id] = block;
  }

  VoxelBlock getBlock(int id) => _blocks[id] ?? VoxelBlock.air;

  bool isSolid(int id) => getBlock(id).isSolid;
  bool isOpaque(int id) => getBlock(id).isOpaque;
}
