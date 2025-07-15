extends Node
class_name TileManager 

var occupied_tiles := {}

func tile_key(position: Vector2) -> String:
	return str(position.snapped(Vector2(16, 16)))

func reserve_tile(position: Vector2, entity: Node) -> bool:
	var key = tile_key(position)
	if occupied_tiles.has(key):
		return false  # Schon belegt
	occupied_tiles[key] = entity
	return true

func release_tile(position: Vector2, entity: Node) -> void:
	var key = tile_key(position)
	if occupied_tiles.get(key) == entity:
		occupied_tiles.erase(key)

func is_tile_occupied(position: Vector2) -> bool:
	var key = tile_key(position)
	return occupied_tiles.has(key)
