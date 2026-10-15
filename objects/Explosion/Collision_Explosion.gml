if other.object_index == Explosion || other.object_index == GreenExplosion {
	var _dir = point_direction(other.x + orandom(1), other.y + orandom(1), x, y)
	
	x += lengthdir_x(6, _dir) * timescale
    y += lengthdir_y(6, _dir) * timescale
}
else if other.object_index == SmallExplosion {
	var _dir = point_direction(other.x + orandom(1), other.y + orandom(1), x, y)
	
	x += lengthdir_x(6, _dir) * timescale
    y += lengthdir_y(6, _dir) * timescale
}