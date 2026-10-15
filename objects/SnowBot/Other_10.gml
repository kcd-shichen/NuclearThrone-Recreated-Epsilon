event_inherited()

if walk > 0 {
    walk -= (1) * timescale
    motion_add(gunangle, (1) * timescale)
    if sprite_index != spr_hurt and meleedamage != 0 {
        if random(2) < (1) * timescale instance_create(x + random(8) - 4, y + 4 + random(4), Dust) sprite_index = spr_fire
    }
}

if sprite_index = spr_fire {
    if speed > (8) * timescale speed = (8) * timescale
} else if speed > (3) * timescale speed = (3) * timescale