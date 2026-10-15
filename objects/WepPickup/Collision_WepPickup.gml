if lockstep_stop
	exit

if speed < (4) * timescale && visible {
	motion_add(point_direction(other.x, other.y, x, y), (2) * timescale)
	if (speed > (4) * timescale) speed = (4) * timescale
}