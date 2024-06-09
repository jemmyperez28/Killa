extends Area2D
@export var tilemap: TileMap



func _on_body_entered(body):
	print(str(body))
	if body == tilemap:
		print("ok")
		var collision_shape = $CollisionShape2D
		var shape = collision_shape.shape
		var collision_polygon = shape.get_collision_polygon()
		
		for point in collision_polygon:
			var global_point = to_global(point)
			var cell = tilemap.local_to_map(global_point)
			#tilemap.set_cellv(cell, TileMap.INVALID_CELL_VALUE )
