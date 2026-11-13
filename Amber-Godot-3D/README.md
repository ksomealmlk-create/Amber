# Amber – The Lost Ember (Godot 4 3D)

This build expands the initial third-person 3D prototype into a playable 110-level progression framework.

## Content included
- 11 themed worlds, each containing 10 levels (110 total).
- Deterministic procedural 3D level layouts: ten route patterns with per-level seeded variation in platform positions, elevations, side routes, hazards, enemy counts, and collectible placement.
- World-specific palettes and environmental dressing for the Forgotten Cavern, Cursed Forest, Poison Mushroom Cave, Skeleton Castle, Lava Kingdom, Ice Kingdom, Ancient Cemetery, Temple of Secrets, Crystal Mine, Dark Castle, and The Final World.
- Third-person free movement in all directions, jump, camera control, touch movement buttons.
- Crystals, spike hazards, patrolling enemies, a guardian encounter on each world's tenth level, and an exit gate that advances progression.
- Progress saved locally in Godot's `user://amber_progress.cfg`.
- Previous/next test buttons for quickly inspecting all 110 stages.
- Original Flutter project retained in `legacy_flutter/` for reference.

## Open
1. Install Godot 4.3 or newer.
2. Extract this archive.
3. Import `project.godot` from Godot Project Manager.
4. Run the project.

## Controls
- WASD / Arrow keys: move in all 3D directions.
- Space: jump.
- Mouse: rotate camera (click game window to capture; Esc releases).
- Touch buttons: move and jump.
- Walk into the glowing gate to complete a stage and advance.

## Honest production status
All 110 level slots are implemented and playable through a procedural level-generation system, with themed variation and seeded layouts. This is not yet a finished commercial-quality conversion: the current Amber/player/enemy visuals are procedural placeholders, and combat, full boss mechanics, detailed hand-authored geometry, polished animations, audio, settings, and Android export/testing remain future work. The original Flutter code and assets are preserved but have not all been ported into equivalent Godot gameplay systems.
