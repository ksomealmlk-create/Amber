// مولَّد تلقائياً: توزيع مجسمات كل عالم (assets/world_props/<world>/...)
const Map<int, WorldPropSet> kWorldProps = {
  1: WorldPropSet('world01_blue_cave', {
    'ground': ['rock_01.png', 'rock_02.png', 'rock_03.png', 'rock_04.png', 'rock_05.png', 'rock_06.png', 'rock_07.png', 'rock_08.png', 'rock_09.png', 'rock_10.png', 'rock_11.png', 'rock_12.png', 'rock_13.png', 'rock_14.png', 'rock_15.png', 'rock_16.png'],
    'ceiling': ['stalactite_01.png', 'stalactite_02.png', 'stalactite_03.png', 'stalactite_04.png', 'stalactite_05.png', 'stalactite_06.png', 'stalactite_07.png', 'stalactite_08.png', 'stalactite_09.png', 'stalactite_10.png', 'stalactite_11.png', 'stalactite_12.png', 'stalactite_13.png', 'stalactite_14.png', 'stalactite_15.png', 'stalactite_16.png'],
    'glow': ['glowplant_01.png', 'glowplant_02.png', 'glowplant_03.png', 'glowplant_04.png', 'glowplant_05.png', 'glowplant_06.png', 'glowplant_07.png'],
    'plants': ['plant_01.png', 'plant_02.png', 'plant_03.png', 'plant_04.png', 'plant_05.png', 'plant_06.png'],
  }, {
    'lizard_idle': ['lizard_idle_00.png', 'lizard_idle_01.png', 'lizard_idle_02.png', 'lizard_idle_03.png'],
    'lizard_walk': ['lizard_walk_00.png', 'lizard_walk_01.png', 'lizard_walk_02.png', 'lizard_walk_03.png', 'lizard_walk_04.png', 'lizard_walk_05.png'],
  }),
  2: WorldPropSet('world02_forest', {
    'rocks': ['rock_01.png', 'rock_02.png', 'rock_03.png'],
    'plants': ['plant_01.png', 'plant_02.png', 'plant_03.png', 'plant_04.png', 'plant_05.png', 'plant_06.png'],
    'vines': ['vine_01.png', 'vine_02.png', 'vine_03.png', 'vine_04.png'],
    'hanging': ['hanging_01.png', 'hanging_02.png', 'hanging_03.png'],
    'trees': ['tree_01.png', 'tree_02.png', 'tree_03.png', 'tree_04.png', 'pixeltree_01.png'],
    'hazards': ['thorn_01.png', 'thorn_02.png', 'thorn_03.png', 'thorn_04.png', 'thorn_05.png', 'thorn_06.png'],
  }, {
    'slime_green': ['slime_green_00.png', 'slime_green_01.png', 'slime_green_02.png', 'slime_green_03.png', 'slime_green_04.png', 'slime_green_05.png', 'slime_green_06.png', 'slime_green_07.png', 'slime_green_08.png', 'slime_green_09.png', 'slime_green_10.png', 'slime_green_11.png', 'slime_green_12.png', 'slime_green_13.png', 'slime_green_14.png', 'slime_green_15.png', 'slime_green_16.png', 'slime_green_17.png', 'slime_green_18.png', 'slime_green_19.png', 'slime_green_20.png', 'slime_green_21.png', 'slime_green_22.png', 'slime_green_23.png', 'slime_green_24.png', 'slime_green_25.png', 'slime_green_26.png', 'slime_green_27.png', 'slime_green_28.png', 'slime_green_29.png'],
    'bunny_idle': ['bunny_idle_00.png', 'bunny_idle_01.png', 'bunny_idle_02.png', 'bunny_idle_03.png'],
    'frog_walk': ['frog_walk_00.png', 'frog_walk_01.png', 'frog_walk_02.png', 'frog_walk_03.png', 'frog_walk_04.png', 'frog_walk_05.png', 'frog_walk_06.png', 'frog_walk_07.png', 'frog_walk_08.png', 'frog_walk_09.png'],
    'plant1': ['plant1_00.png', 'plant1_01.png', 'plant1_02.png', 'plant1_03.png', 'plant1_04.png', 'plant1_05.png', 'plant1_06.png', 'plant1_07.png', 'plant1_08.png', 'plant1_09.png', 'plant1_10.png', 'plant1_11.png', 'plant1_12.png', 'plant1_13.png', 'plant1_14.png', 'plant1_15.png', 'plant1_16.png', 'plant1_17.png', 'plant1_18.png', 'plant1_19.png', 'plant1_20.png', 'plant1_21.png', 'plant1_22.png', 'plant1_23.png', 'plant1_24.png', 'plant1_25.png', 'plant1_26.png', 'plant1_27.png', 'plant1_28.png', 'plant1_29.png'],
    'plant2': ['plant2_00.png', 'plant2_01.png', 'plant2_02.png', 'plant2_03.png', 'plant2_04.png', 'plant2_05.png', 'plant2_06.png', 'plant2_07.png', 'plant2_08.png', 'plant2_09.png', 'plant2_10.png', 'plant2_11.png', 'plant2_12.png', 'plant2_13.png', 'plant2_14.png', 'plant2_15.png', 'plant2_16.png', 'plant2_17.png', 'plant2_18.png', 'plant2_19.png', 'plant2_20.png', 'plant2_21.png', 'plant2_22.png', 'plant2_23.png', 'plant2_24.png', 'plant2_25.png', 'plant2_26.png', 'plant2_27.png', 'plant2_28.png', 'plant2_29.png'],
  }),
  3: WorldPropSet('world03_mushroom', {
    'glow': ['glowstalk_01.png', 'glowstalk_02.png', 'glowstalk_03.png', 'glowstalk_04.png', 'glowstalk_05.png', 'glowstalk_06.png', 'glowstalk_07.png'],
    'pods': ['pod_01.png', 'pod_02.png', 'pod_03.png', 'pod_04.png'],
    'plants': ['plant_01.png', 'plant_02.png', 'plant_03.png', 'plant_04.png', 'plant_05.png', 'plant_06.png'],
    'rocks': ['rock_01.png', 'rock_02.png', 'rock_03.png'],
    'hanging': ['hanging_01.png', 'hanging_02.png', 'hanging_03.png'],
  }, {
    'mushroom_walk': ['mushroom_walk_00.png', 'mushroom_walk_01.png', 'mushroom_walk_02.png', 'mushroom_walk_03.png', 'mushroom_walk_04.png', 'mushroom_walk_05.png', 'mushroom_walk_06.png', 'mushroom_walk_07.png', 'mushroom_walk_08.png', 'mushroom_walk_09.png'],
    'mushroom_jump': ['mushroom_jump_00.png', 'mushroom_jump_01.png', 'mushroom_jump_02.png', 'mushroom_jump_03.png', 'mushroom_jump_04.png', 'mushroom_jump_05.png', 'mushroom_jump_06.png', 'mushroom_jump_07.png', 'mushroom_jump_08.png'],
    'blueflower1': ['blueflower1_00.png', 'blueflower1_01.png', 'blueflower1_02.png', 'blueflower1_03.png', 'blueflower1_04.png', 'blueflower1_05.png', 'blueflower1_06.png', 'blueflower1_07.png', 'blueflower1_08.png', 'blueflower1_09.png', 'blueflower1_10.png', 'blueflower1_11.png', 'blueflower1_12.png', 'blueflower1_13.png', 'blueflower1_14.png', 'blueflower1_15.png', 'blueflower1_16.png', 'blueflower1_17.png', 'blueflower1_18.png', 'blueflower1_19.png'],
    'blueflower2': ['blueflower2_00.png', 'blueflower2_01.png', 'blueflower2_02.png', 'blueflower2_03.png', 'blueflower2_04.png', 'blueflower2_05.png', 'blueflower2_06.png', 'blueflower2_07.png', 'blueflower2_08.png', 'blueflower2_09.png', 'blueflower2_10.png', 'blueflower2_11.png', 'blueflower2_12.png', 'blueflower2_13.png', 'blueflower2_14.png', 'blueflower2_15.png', 'blueflower2_16.png', 'blueflower2_17.png', 'blueflower2_18.png', 'blueflower2_19.png'],
    'plant4': ['plant4_00.png', 'plant4_01.png', 'plant4_02.png', 'plant4_03.png', 'plant4_04.png', 'plant4_05.png', 'plant4_06.png', 'plant4_07.png', 'plant4_08.png', 'plant4_09.png', 'plant4_10.png', 'plant4_11.png', 'plant4_12.png', 'plant4_13.png', 'plant4_14.png', 'plant4_15.png', 'plant4_16.png', 'plant4_17.png', 'plant4_18.png', 'plant4_19.png'],
  }),
  4: WorldPropSet('world04_castle', {
    'structures': ['castle_01.png', 'castle_02.png', 'castle_03.png', 'castle_04.png', 'castle_05.png', 'castle_06.png', 'castle_07.png', 'castle_08.png'],
    'gates': ['gate_01.png', 'gate_02.png', 'gate_03.png', 'gate_04.png', 'gate_05.png', 'gate_06.png'],
    'ruins': ['ruin_01.png', 'ruin_02.png', 'ruin_03.png', 'ruin_04.png', 'ruin_05.png', 'ruin_06.png'],
    'far': ['far_01.png', 'far_02.png', 'far_03.png', 'far_04.png', 'far_05.png', 'far_06.png'],
  }, {
    'wizard_idle': ['wizard_idle_00.png', 'wizard_idle_01.png', 'wizard_idle_02.png', 'wizard_idle_03.png', 'wizard_idle_04.png', 'wizard_idle_05.png', 'wizard_idle_06.png', 'wizard_idle_07.png', 'wizard_idle_08.png', 'wizard_idle_09.png'],
    'wizard_walk': ['wizard_walk_00.png', 'wizard_walk_01.png', 'wizard_walk_02.png', 'wizard_walk_03.png', 'wizard_walk_04.png', 'wizard_walk_05.png', 'wizard_walk_06.png', 'wizard_walk_07.png', 'wizard_walk_08.png', 'wizard_walk_09.png'],
  }),
  5: WorldPropSet('world05_lava', {
    'ground': ['rock_01.png', 'rock_02.png', 'rock_03.png', 'rock_04.png', 'rock_05.png', 'rock_06.png', 'rock_07.png', 'rock_08.png', 'rock_09.png', 'rock_10.png', 'rock_11.png', 'rock_12.png', 'rock_13.png', 'rock_14.png', 'rock_15.png', 'rock_16.png'],
    'ceiling': ['stalactite_01.png', 'stalactite_02.png', 'stalactite_03.png', 'stalactite_04.png', 'stalactite_05.png', 'stalactite_06.png', 'stalactite_07.png', 'stalactite_08.png', 'stalactite_09.png', 'stalactite_10.png', 'stalactite_11.png', 'stalactite_12.png', 'stalactite_13.png', 'stalactite_14.png', 'stalactite_15.png', 'stalactite_16.png'],
    'hazards': ['firethorn_01.png', 'firethorn_02.png', 'firethorn_03.png', 'firethorn_04.png', 'firethorn_05.png', 'firethorn_06.png'],
    'vines': ['charredvine_01.png', 'charredvine_02.png', 'charredvine_03.png', 'charredvine_04.png'],
  }, {
    'slime_orange': ['slime_orange_00.png', 'slime_orange_01.png', 'slime_orange_02.png', 'slime_orange_03.png', 'slime_orange_04.png', 'slime_orange_05.png', 'slime_orange_06.png', 'slime_orange_07.png', 'slime_orange_08.png', 'slime_orange_09.png', 'slime_orange_10.png', 'slime_orange_11.png', 'slime_orange_12.png', 'slime_orange_13.png', 'slime_orange_14.png', 'slime_orange_15.png', 'slime_orange_16.png', 'slime_orange_17.png', 'slime_orange_18.png', 'slime_orange_19.png', 'slime_orange_20.png', 'slime_orange_21.png', 'slime_orange_22.png', 'slime_orange_23.png', 'slime_orange_24.png', 'slime_orange_25.png', 'slime_orange_26.png', 'slime_orange_27.png', 'slime_orange_28.png', 'slime_orange_29.png'],
    'boss_dragon_idle': ['dragon_idle_00.png', 'dragon_idle_01.png', 'dragon_idle_02.png', 'dragon_idle_03.png', 'dragon_idle_04.png', 'dragon_idle_05.png'],
    'boss_dragon_breath': ['dragon_breath_00.png', 'dragon_breath_01.png', 'dragon_breath_02.png', 'dragon_breath_03.png', 'dragon_breath_04.png', 'dragon_breath_05.png', 'dragon_breath_06.png'],
    'fireball': ['fireball_00.png', 'fireball_01.png', 'fireball_02.png'],
  }),
  6: WorldPropSet('world06_ice', {
    'ground': ['icerock_01.png', 'icerock_02.png', 'icerock_03.png', 'icerock_04.png', 'icerock_05.png', 'icerock_06.png', 'icerock_07.png', 'icerock_08.png', 'icerock_09.png', 'icerock_10.png', 'icerock_11.png', 'icerock_12.png', 'icerock_13.png', 'icerock_14.png', 'icerock_15.png', 'icerock_16.png'],
    'ceiling': ['icicle_01.png', 'icicle_02.png', 'icicle_03.png', 'icicle_04.png', 'icicle_05.png', 'icicle_06.png', 'icicle_07.png', 'icicle_08.png', 'icicle_09.png', 'icicle_10.png', 'icicle_11.png', 'icicle_12.png', 'icicle_13.png', 'icicle_14.png', 'icicle_15.png', 'icicle_16.png'],
    'plants': ['frostplant_01.png', 'frostplant_02.png', 'frostplant_03.png', 'frostplant_04.png', 'frostplant_05.png', 'frostplant_06.png'],
    'trees': ['pine_01.png', 'pine_02.png'],
  }, {
    'bird': ['bird_sheet.png'],
    'plant3': ['plant3_00.png', 'plant3_01.png', 'plant3_02.png', 'plant3_03.png', 'plant3_04.png', 'plant3_05.png', 'plant3_06.png', 'plant3_07.png', 'plant3_08.png', 'plant3_09.png', 'plant3_10.png', 'plant3_11.png', 'plant3_12.png', 'plant3_13.png', 'plant3_14.png', 'plant3_15.png', 'plant3_16.png', 'plant3_17.png', 'plant3_18.png', 'plant3_19.png', 'plant3_20.png', 'plant3_21.png', 'plant3_22.png', 'plant3_23.png', 'plant3_24.png', 'plant3_25.png', 'plant3_26.png', 'plant3_27.png', 'plant3_28.png', 'plant3_29.png'],
  }),
  7: WorldPropSet('world07_graveyard', {
    'graves': ['grave_01.png', 'grave_02.png', 'grave_03.png', 'grave_04.png', 'grave_05.png', 'grave_06.png', 'grave_07.png', 'grave_08.png', 'grave_09.png', 'grave_10.png', 'grave_11.png', 'grave_12.png', 'grave_13.png', 'grave_14.png'],
    'crypts': ['crypt_01.png', 'crypt_02.png', 'crypt_03.png', 'crypt_04.png', 'crypt_05.png', 'crypt_06.png', 'crypt_07.png'],
    'fences': ['fence_01.png', 'fence_02.png', 'fence_03.png', 'fence_04.png', 'fence_05.png', 'fence_06.png', 'fence_07.png', 'fence_08.png', 'fence_09.png', 'fence_10.png', 'fence_11.png', 'fence_12.png'],
    'props': ['prop_01.png', 'prop_02.png', 'prop_03.png', 'prop_04.png', 'prop_05.png', 'prop_06.png', 'prop_07.png', 'prop_08.png', 'prop_09.png', 'prop_10.png', 'prop_11.png', 'prop_12.png', 'prop_13.png', 'prop_14.png', 'prop_15.png', 'prop_16.png', 'prop_17.png', 'prop_18.png', 'prop_19.png', 'prop_20.png', 'prop_21.png', 'prop_22.png', 'prop_23.png', 'prop_24.png', 'prop_25.png', 'prop_26.png', 'prop_27.png', 'prop_28.png', 'prop_29.png'],
    'creatures': ['creature_01.png', 'creature_02.png', 'creature_03.png', 'creature_04.png', 'creature_05.png'],
  }, {
    'ghost': ['ghost_sheet.png'],
    'ghost_particles': ['ghost_particles_sheet.png'],
  }),
  8: WorldPropSet('world08_temple', {
    'columns': ['column_01.png', 'column_02.png', 'column_03.png', 'column_04.png', 'column_05.png'],
    'arches': ['arch_01.png', 'arch_02.png', 'arch_03.png', 'arch_04.png'],
    'gates': ['gate_01.png', 'gate_02.png', 'gate_03.png', 'gate_04.png', 'gate_05.png', 'gate_06.png', 'gate_07.png'],
    'statues': ['stone_01.png', 'stone_02.png', 'stone_03.png', 'stone_04.png', 'stone_05.png', 'stone_06.png', 'stone_07.png', 'stone_08.png'],
    'light': ['light_01.png', 'light_02.png', 'light_03.png'],
  }, {
    'snake_idle': ['snake_idle_00.png', 'snake_idle_01.png', 'snake_idle_02.png', 'snake_idle_03.png'],
    'snake_attack': ['snake_attack_00.png'],
    'slash': ['slash_00.png', 'slash_01.png', 'slash_02.png', 'slash_03.png', 'slash_04.png'],
  }),
  9: WorldPropSet('world09_crystal', {
    'ground': ['crystalrock_01.png', 'crystalrock_02.png', 'crystalrock_03.png', 'crystalrock_04.png', 'crystalrock_05.png', 'crystalrock_06.png', 'crystalrock_07.png', 'crystalrock_08.png', 'crystalrock_09.png', 'crystalrock_10.png', 'crystalrock_11.png', 'crystalrock_12.png', 'crystalrock_13.png', 'crystalrock_14.png', 'crystalrock_15.png', 'crystalrock_16.png'],
    'ceiling': ['crystalhang_01.png', 'crystalhang_02.png', 'crystalhang_03.png', 'crystalhang_04.png', 'crystalhang_05.png', 'crystalhang_06.png', 'crystalhang_07.png', 'crystalhang_08.png', 'crystalhang_09.png', 'crystalhang_10.png', 'crystalhang_11.png', 'crystalhang_12.png', 'crystalhang_13.png', 'crystalhang_14.png', 'crystalhang_15.png', 'crystalhang_16.png'],
    'glow': ['glowshoot_01.png', 'glowshoot_02.png', 'glowshoot_03.png', 'glowshoot_04.png', 'glowshoot_05.png', 'glowshoot_06.png', 'glowshoot_07.png'],
    'pods': ['pod_01.png', 'pod_02.png', 'pod_03.png', 'pod_04.png'],
    'gems': ['gem_01.png', 'gem_02.png', 'gem_03.png', 'gem_04.png', 'gem_05.png', 'gem_06.png', 'gem_07.png', 'gem_08.png', 'gem_09.png', 'gem_10.png', 'gem_11.png', 'gem_12.png'],
  }, {
    'lizard_idle': ['lizard_idle_00.png', 'lizard_idle_01.png', 'lizard_idle_02.png', 'lizard_idle_03.png'],
    'snake_walk': ['snake_walk_00.png', 'snake_walk_01.png', 'snake_walk_02.png', 'snake_walk_03.png'],
    'electro_shock': ['shock_00.png', 'shock_01.png', 'shock_02.png', 'shock_03.png', 'shock_04.png', 'shock_05.png', 'shock_06.png', 'shock_07.png', 'shock_08.png'],
  }),
  10: WorldPropSet('world10_dark_castle', {
    'structures': ['castle_01.png', 'castle_02.png', 'castle_03.png', 'castle_04.png', 'castle_05.png', 'castle_06.png', 'castle_07.png', 'castle_08.png'],
    'gates': ['gate_01.png', 'gate_02.png', 'gate_03.png', 'gate_04.png', 'gate_05.png', 'gate_06.png'],
    'ruins': ['ruin_01.png', 'ruin_02.png', 'ruin_03.png', 'ruin_04.png', 'ruin_05.png', 'ruin_06.png'],
    'fences': ['dark_01.png', 'dark_02.png', 'dark_03.png', 'dark_04.png', 'dark_05.png', 'dark_06.png', 'dark_07.png', 'dark_08.png'],
    'hazards': ['darkthorn_01.png', 'darkthorn_02.png', 'darkthorn_03.png', 'darkthorn_04.png', 'darkthorn_05.png', 'darkthorn_06.png'],
  }, {
    'wizard_idle': ['wizard_idle_00.png', 'wizard_idle_01.png', 'wizard_idle_02.png', 'wizard_idle_03.png', 'wizard_idle_04.png', 'wizard_idle_05.png', 'wizard_idle_06.png', 'wizard_idle_07.png', 'wizard_idle_08.png', 'wizard_idle_09.png'],
    'ghost': ['ghost_sheet.png'],
    'enemy_death': ['death_00.png', 'death_01.png', 'death_02.png', 'death_03.png', 'death_04.png', 'death_05.png', 'death_06.png', 'death_07.png'],
  }),
  11: WorldPropSet('world11_floating_islands', {
    'platforms': ['island_01.png', 'island_02.png', 'island_03.png', 'island_04.png', 'island_05.png'],
    'rocks': ['rock_01.png', 'rock_02.png', 'rock_03.png'],
    'plants': ['plant_01.png', 'plant_02.png', 'plant_03.png', 'plant_04.png', 'plant_05.png', 'plant_06.png'],
    'hanging': ['hanging_01.png', 'hanging_02.png', 'hanging_03.png', 'hanging_04.png', 'hanging_05.png', 'hanging_06.png'],
    'glow': ['glowshoot_01.png', 'glowshoot_02.png', 'glowshoot_03.png', 'glowshoot_04.png', 'glowshoot_05.png', 'glowshoot_06.png', 'glowshoot_07.png'],
    'crystals': ['shard_01.png', 'shard_02.png', 'shard_03.png', 'shard_04.png', 'shard_05.png', 'shard_06.png'],
  }, {
    'wizard_walk': ['wizard_walk_00.png', 'wizard_walk_01.png', 'wizard_walk_02.png', 'wizard_walk_03.png', 'wizard_walk_04.png', 'wizard_walk_05.png', 'wizard_walk_06.png', 'wizard_walk_07.png', 'wizard_walk_08.png', 'wizard_walk_09.png'],
    'wizard_dash': ['wizard_dash_00.png', 'wizard_dash_01.png', 'wizard_dash_02.png', 'wizard_dash_03.png', 'wizard_dash_04.png', 'wizard_dash_05.png', 'wizard_dash_06.png', 'wizard_dash_07.png', 'wizard_dash_08.png', 'wizard_dash_09.png', 'wizard_dash_10.png', 'wizard_dash_11.png', 'wizard_dash_12.png', 'wizard_dash_13.png', 'wizard_dash_14.png', 'wizard_dash_15.png'],
    'bird': ['bird_sheet.png'],
    'energy_field': ['energy_00.png', 'energy_01.png', 'energy_02.png', 'energy_03.png', 'energy_04.png', 'energy_05.png', 'energy_06.png', 'energy_07.png'],
  }),
};

class WorldPropSet {
  final String dir;
  final Map<String, List<String>> props;   // assets/world_props/<dir>/<file>
  final Map<String, List<String>> enemies; // assets/world_props/<dir>/enemies/<file>
  const WorldPropSet(this.dir, this.props, this.enemies);
  String prop(String f) => 'assets/world_props/$dir/$f';
  String enemy(String f) => 'assets/world_props/$dir/enemies/$f';
}
