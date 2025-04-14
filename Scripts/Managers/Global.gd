extends Node

var fox_reputation: int = 0

var reputations := {
	fox = 0
}

func get_reputation(npc_name: String) -> int:
	if npc_name in reputations:
		return reputations[npc_name]
	return 0

func set_reputation(npc_name: String, value: int) -> void:
	reputations[npc_name] = clamp(value, -10, 10)

func change_reputations(npc_name: String, delta: int) -> void:
	var current = get_reputation(npc_name)
	set_reputation(npc_name, current + delta)
