#!/bin/bash
# Generates .tscn files for all alternative bosses
# Uses boss_generic.gd script with customized stats

SCENES_DIR="$(dirname "$0")/../../scenes/enemies"

create_boss() {
    local filename="$1"
    local node_name="$2"
    local boss_name="$3"
    local hp="$4"
    local dmg="$5"
    local spd="$6"
    local color_r="$7"
    local color_g="$8"
    local color_b="$9"
    local style="${10}"
    local scale="${11:-3.5}"

    cat > "$SCENES_DIR/$filename.tscn" << TSCNEOF
[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/enemies/boss_generic.gd" id="1"]

[sub_resource type="CapsuleMesh" id="1"]
radius = 0.5
height = 2.0

[sub_resource type="CapsuleShape3D" id="2"]
radius = 0.5
height = 2.0

[sub_resource type="SphereShape3D" id="3"]
radius = 0.8

[node name="$node_name" type="CharacterBody3D" groups=["enemies", "boss"]]
collision_layer = 2
collision_mask = 1
transform = Transform3D($scale, 0, 0, 0, $scale, 0, 0, 0, $scale, 0, 0, 0)
script = ExtResource("1")
speed = $spd
max_hp = $hp
damage = $dmg
xp_drop = 200
enemy_color = Color($color_r, $color_g, $color_b, 1)
boss_name = "$boss_name"
boss_color = Color($color_r, $color_g, $color_b, 1)
attack_style = "$style"

[node name="Mesh" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.0, 0)
mesh = SubResource("1")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.0, 0)
shape = SubResource("2")

[node name="Hitbox" type="Area3D" parent="."]
collision_layer = 2
collision_mask = 1

[node name="HitboxShape" type="CollisionShape3D" parent="Hitbox"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.0, 0)
shape = SubResource("3")
TSCNEOF
    echo "Created: $filename.tscn"
}

# Cemetery
create_boss "boss_cemetery_lich" "BossCemeteryLich" "Lich King" 3000 35 3.0 0.3 0.8 0.3 "summoner"
create_boss "boss_cemetery_reaper" "BossCemeteryReaper" "Death Reaper" 2500 50 5.0 0.1 0.1 0.15 "melee"

# Forest
create_boss "boss_forest_elder" "BossForestElder" "Elder Treant" 4000 25 1.5 0.2 0.5 0.1 "summoner" 4.0
create_boss "boss_forest_spider" "BossForestSpider" "Spider Queen" 2800 40 4.5 0.4 0.1 0.5 "ranged"

# Farm
create_boss "boss_farm_scarecrow" "BossFarmScarecrow" "Scarecrow King" 2500 45 4.0 0.6 0.4 0.1 "melee"
create_boss "boss_farm_harvester" "BossFarmHarvester" "The Harvester" 3500 35 3.0 0.3 0.3 0.3 "balanced"

# Tokyo
create_boss "boss_tokyo_shogun" "BossTokyoShogun" "Cyber Shogun" 3000 45 5.0 0.8 0.1 0.3 "melee"
create_boss "boss_tokyo_kaiju" "BossTokyoKaiju" "Mini Kaiju" 5000 30 2.0 0.2 0.6 0.3 "balanced" 5.0

# Volcano
create_boss "boss_volcano_phoenix" "BossVolcanoPhoenix" "Ash Phoenix" 2500 40 6.0 1.0 0.5 0.0 "ranged"
create_boss "boss_volcano_titan" "BossVolcanoTitan" "Magma Titan" 5000 25 1.5 0.5 0.1 0.0 "summoner" 5.0

# Ocean
create_boss "boss_ocean_siren" "BossOceanSiren" "Siren Queen" 2800 35 4.0 0.3 0.7 0.9 "ranged"
create_boss "boss_ocean_hydra" "BossOceanHydra" "Deep Hydra" 4500 30 2.5 0.1 0.2 0.4 "summoner" 4.5

# Arena
create_boss "boss_arena_minotaur" "BossArenaMinotaur" "Minotaur Champion" 3500 50 5.0 0.6 0.3 0.1 "melee" 4.0
create_boss "boss_arena_chimera" "BossArenaChimera" "Chimera" 3000 40 4.0 0.5 0.2 0.6 "balanced"

# Space
create_boss "boss_space_hivemind" "BossSpaceHivemind" "Hive Mind" 3000 30 2.0 0.2 0.8 0.2 "summoner"
create_boss "boss_space_warden" "BossSpaceWarden" "Void Warden" 3500 45 3.5 0.4 0.2 0.8 "ranged"

# Castle
create_boss "boss_castle_werewolf" "BossCastleWerewolf" "Alpha Werewolf" 2800 55 7.0 0.4 0.3 0.2 "melee"
create_boss "boss_castle_banshee" "BossCastleBanshee" "Banshee Queen" 2500 35 5.0 0.5 0.7 0.9 "ranged"

# Candy
create_boss "boss_candy_witch" "BossCandyWitch" "Candy Witch" 2800 40 4.0 0.9 0.3 0.7 "ranged"
create_boss "boss_candy_dragon" "BossCandyDragon" "Gummy Dragon" 4000 35 3.0 0.2 0.8 0.4 "balanced" 4.5

echo "Done! Created 20 alt boss scenes."
