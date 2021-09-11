extends Node2D

func _ready():
	createPolygonFromSpriteTexture($Sprite)

func createPolygonFromSpriteTexture(sprite):
	var image = sprite.texture.get_data()

	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(image)
	
	var polygons = bitmap.opaque_to_polygons(Rect2(Vector2(bitmap.get_size().x/2,0), bitmap.get_size()),1) #RECT can be used to specify which section of the sprite to sample
	
	var polycopy = []
	for point in polygons[0]:
		polycopy.append(Vector2(-point.x,point.y))
	var final = Geometry.merge_polygons_2d(polygons[0],polycopy)
#	final = Geometry.offset_polygon_2d(final[0],30)
#	final = Geometry.offset_polygon_2d(final[0],-30) #Cheap hacky rounding-off-corners method. Use UNION of this and the original polygon to snip pointy bits while preserving corners.
	for polygon in final:
		var collider = CollisionPolygon2D.new()
		collider.polygon = polygon
		collider.position = Vector2(0, -bitmap.get_size().y/2)
		add_child(collider)
