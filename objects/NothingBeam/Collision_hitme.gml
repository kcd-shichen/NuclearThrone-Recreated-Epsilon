if (!disappear && scr_can_hit(other.id, (other.object_index == Player))) {
	scr_hit(other.id, 5, hitid)
	
	with (other) {
		motion_add(270, (12) * timescale)
		if (speed > (16) * timescale) speed = (16) * timescale
	}
}