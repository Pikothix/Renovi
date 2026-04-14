# Multi-Signal Chunked World Foundation

This prototype is now structured as a landmass-first biome and terrain pipeline for a chunked 2D top-down world.

## Generation pipeline

Each logical world cell is generated in four explicit stages inside `res://scripts/world_generator.gd`.

1. World signals
   - `landmass`
   - `moisture`
   - `temperature`
   - `uplift`
2. Landmass classification
   - low `landmass` becomes ocean water first
   - values just above sea level become coastline
   - higher values become inland land
3. Biome context classification
   - Ocean
   - Coast
   - Plains
   - Jungle
   - Wetland
   - Rocky Upland
4. Final terrain output
   - Deep Water
   - Shallow Water
   - Sand
   - Dirt
   - Grass
   - Jungle Ground
   - Clay
   - Stone

This is the key distinction in the project:

- biome context describes the broader regional identity
- terrain type describes the actual tile result used by rendering and gameplay

## First ruleset

The current rules are intentionally explicit and easy to tune.

### Landmass and water

- `landmass < deep_water_threshold` -> `Deep Water`
- `landmass < sea_level` -> `Shallow Water`
- `landmass < sea_level + coastline_width` -> `Coast` biome band

### Land biomes

- high temperature + high moisture -> `Jungle`
- high moisture + low landmass/uplift -> `Wetland`
- high landmass or high uplift or dry conditions -> `Rocky Upland`
- otherwise -> `Plains`

### Terrain output

- `Ocean` -> deep or shallow water
- `Coast` -> mostly sand, with some dirt/grass inland
- `Plains` -> mostly grass with dirt fallback
- `Jungle` -> jungle ground with some grass/dirt
- `Wetland` -> clay, dirt, grass, and some shallow water near sea level
- `Rocky Upland` -> stone with dirt/grass fallback

## Deterministic chunk generation

- `res://scripts/chunk_manager.gd` streams chunks around the player using `load_radius`
- chunks outside `unload_radius` are freed
- each tile is sampled from absolute world coordinates, so chunk borders stay seamless
- the world is deterministic from `world_seed`
- no persistence is required yet because chunks can be regenerated from the same seed and settings

Logical tile data lives in `res://scripts/chunk_data.gd`, while rendering stays separate.

## Settings and inspector tuning

World generation settings now live in `res://scripts/worldgen_settings.gd` as a dedicated `WorldGenSettings` resource. `ChunkManager` owns one exported resource instance, so tuning stays grouped in the inspector instead of being scattered across gameplay code.

### Chunk settings on `ChunkManager`

- `chunk_size`
- `cell_size`
- `load_radius`
- `unload_radius`

### World generation settings on `WorldGenSettings`

- `world_seed`
- signal noise settings such as `noise_type`, `fractal_octaves`, `fractal_lacunarity`, `fractal_gain`
- per-signal frequencies and offsets for `landmass`, `moisture`, `temperature`, and `uplift`
- latitude shaping for temperature
- thresholds such as `deep_water_threshold`, `sea_level`, `coastline_width`
- biome thresholds such as `jungle_temperature_threshold`, `jungle_moisture_threshold`, `wetland_*`, `rocky_*`, `stone_*`
- terrain colors
- terrain blend and shoreline settings
- preview settings like `preview_size` and `preview_world_span`

## In-editor preview maps

`res://scripts/worldgen_preview.gd` renders small in-editor preview textures for:

- landmass
- temperature
- moisture
- biome classification

The preview panel reads the same `WorldGenSettings` resource used at runtime, so inspector changes flow directly into the preview. It only refreshes periodically and is meant for tuning, not for generating runtime chunk visuals every frame.

## Terrain and biome definitions

- `res://scripts/terrain_definitions.gd` stores terrain metadata such as id, display name, walkability, color, and tags
- `res://scripts/biome_definitions.gd` stores biome metadata such as id, display name, debug color, and description

This keeps biome context and terrain output separate, and it gives future systems a clean place to ask questions like:

- is this tile aquatic?
- is this terrain rocky?
- is this biome jungle-like?

## Rendering

- `res://scripts/terrain_renderer.gd` converts logical terrain ids into a tiny chunk texture
- `res://shaders/terrain_blend.gdshader` softens square edges with terrain-aware color blending
- shorelines remain clearer than land-to-land transitions
- gameplay still uses logical terrain ids, not shader output

Water remains non-walkable through `TerrainDefinitions.is_walkable`, and player movement checks logical terrain data directly.

## Tile inspection

Hold right mouse on any visible tile to inspect it live with a tooltip near the cursor.

The inspector shows:

- world cell
- chunk coordinates
- local cell coordinates
- landmass
- moisture
- temperature
- uplift
- biome context
- terrain type
- walkable state
- whether the chunk is currently loaded
- chunk seed
- loaded chunk count
- player chunk

This is the main tool for understanding why a tile became what it is.

## Controls

- `WASD`: move
- mouse wheel: zoom
- hold right mouse: inspect tile under cursor
- `G`: toggle logical grid
- `B`: toggle chunk borders
- `V`: toggle biome overlay
- `F1`: toggle debug panel
- `R`: randomize seed and regenerate world

## Where future signals fit

Future world signals such as pollution, corruption, fertility, or magic fit naturally into the same pipeline:

1. add the signal to `WorldGenSettings`
2. sample it in `world_generator.gd`
3. expose it through tile debug data
4. use it in biome, terrain, or future spawn rules

That means the current foundation is already shaped for later terrain variants, prop spawning rules, and richer biome-aware world simulation.
