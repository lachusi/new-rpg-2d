extends Node
class_name TileManager 

var occupied_tiles := {}

# Debug Toggle
var debug_enabled := true
var debug_frame_counter := 0

func _process(_delta):
	debug_frame_counter += 1

func tile_key(position: Vector2) -> String:
	return str(position.snapped(Vector2(16, 16)))

func reserve_tile(position: Vector2, entity: Node) -> bool:
	var key = tile_key(position)
	var ok = not occupied_tiles.has(key)
	if ok:
		occupied_tiles[key] = entity
	if debug_enabled:
		print("[TileManager][RESERVE]", key, "->", entity, " ok=", ok, " total=", occupied_tiles.size())
	if not ok and debug_enabled:
		var holder = occupied_tiles[key]
		print("  └─ blockiert durch:", holder, " freed? ", not is_instance_valid(holder))
	return ok

func release_tile(position: Vector2, entity: Node) -> void:
	var key = tile_key(position)
	if occupied_tiles.get(key) == entity:
		occupied_tiles.erase(key)
		if debug_enabled:
			print("[TileManager][RELEASE]", key, " entity=", entity, " total=", occupied_tiles.size())
	elif debug_enabled:
		print("[TileManager][RELEASE-SKIP]", key, " passt nicht zu entity=", entity, " holder=", occupied_tiles.get(key))

func sweep():
	var removed := []
	for k in occupied_tiles.keys():
		var e = occupied_tiles[k]
		# Ungültig oder steht nicht mehr wirklich auf diesem Key
		if not is_instance_valid(e) or tile_key(e.position) != k:
			removed.append(k)
	for k in removed:
		occupied_tiles.erase(k)
	if debug_enabled and removed.size() > 0:
		print("[TileManager][SWEEP] removed=", removed, " total=", occupied_tiles.size())

func rebuild_from_scene():
	occupied_tiles.clear()
	var groups = ["Player", "Enemy", "NPC"]
	for g in groups:
		for e in get_tree().get_nodes_in_group(g):
			if not is_instance_valid(e):
				continue
			var k = tile_key(e.position)
			if not occupied_tiles.has(k):
				occupied_tiles[k] = e
	if debug_enabled:
		print("[TileManager][REBUILD] total=", occupied_tiles.size())

func is_tile_occupied(position: Vector2) -> bool:
	return occupied_tiles.has(tile_key(position))

func release_entity(entity: Node) -> void:
	var removed: Array = []
	for k in occupied_tiles.keys():
		if occupied_tiles[k] == entity:
			removed.append(k)
	for k in removed:
		occupied_tiles.erase(k)
	if debug_enabled:
		print("[TileManager][RELEASE_ENTITY]", entity, " removed_keys=", removed, " total=", occupied_tiles.size())

# Debug-Hilfen
func debug_dump():
	print("=== TileManager Dump (", occupied_tiles.size(), " entries ) ===")
	for k in occupied_tiles.keys():
		var e = occupied_tiles[k]
		print(" ", k, " -> ", e, " valid=", is_instance_valid(e))
	print("=== End Dump ===")

func debug_find_stale():
	var stale := []
	for k in occupied_tiles.keys():
		if not is_instance_valid(occupied_tiles[k]):
			stale.append(k)
	if stale.size() > 0:
		print("[TileManager][STALE] keys=", stale)
	else:
		print("[TileManager][STALE] keine")

func debug_entity(entity: Node):
	var held := []
	for k in occupied_tiles.keys():
		if occupied_tiles[k] == entity:
			held.append(k)
	print("[TileManager][ENTITY]", entity, " keys=", held, " valid=", is_instance_valid(entity))

func debug_duplicates():
	var counts := {}
	for k in occupied_tiles.keys():
		var e = occupied_tiles[k]
		if not counts.has(e):
			counts[e] = []
		counts[e].append(k)
	for e in counts.keys():
		if counts[e].size() > 1:
			print("[TileManager][DUP]", e, " ->", counts[e])
