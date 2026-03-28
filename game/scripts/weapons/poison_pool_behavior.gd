extends Node

## Comportamento da poca de veneno: causa dano periodico e se destroi apos lifetime.

var life_timer: float = 0.0
var damage_timer: float = 0.0
var damage_interval: float = 0.5

func _ready() -> void:
	life_timer = get_meta("lifetime")
	# Register as elemental zone for cross-combo
	var area: Area3D = get_meta("area")
	if is_instance_valid(area):
		var owner_peer = MultiplayerManager.local_player_id if MultiplayerManager.is_online else 1
		SynergySystem.register_elemental_zone(area.global_position, "poison", owner_peer, life_timer)

func _process(delta: float) -> void:
	if GameManager.paused:
		return

	life_timer -= delta
	if life_timer <= 0:
		get_parent().queue_free()
		return

	damage_timer -= delta
	if damage_timer <= 0:
		damage_timer = damage_interval
		_deal_damage()

func _deal_damage() -> void:
	var area: Area3D = get_meta("area")
	if not is_instance_valid(area):
		return
	var dmg: int = get_meta("damage")
	var bodies = area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			GameManager._last_attacking_weapon = "poison_bottle"
			body.call_deferred("take_damage", dmg, "poison")
