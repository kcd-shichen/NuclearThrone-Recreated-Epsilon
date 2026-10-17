/// @function scr_hit
/// @param instance
/// @param amount
/// @param {Enum.HitId|Array} hitid=HitId.None
function scr_hit(_instance, _amount, _hitid = HitId.None) {
	with (_instance) {
		if (instance_is(self, Player)) {
			var _adj = scrCustomParam("damage_to_player", 0)
			if (_amount != 0 && _adj != 0) _amount = max(1, _amount + _adj)
			if (scrPlayerProcTakeDamage(_amount)) return false
			if (is_array(_hitid) || (_hitid >= 0 && _hitid != HitId.Player)) {
				if (scr_player_is_local(index) && _amount > 0) GameCont.deathcause = _hitid
			}
			drawlowhp = 30
		}
		
		if (_amount > 0) {
			nexthurt = current_frame + 6
			hp -= _amount
		}
		
		sprite_index = spr_hurt
		image_index = 0
		
		snd_play_hit(snd_hurt, 0.2)
		
		if (global.__debug_health) {
			if (is_array(_hitid) || _hitid >= 0) {
				print(real(id), object_get_name(object_index), $"{hp}/{max_hp}", "was hit by", _amount, "from", scrDeathCauseGetName(_hitid), $"({object_get_name(other.object_index)})")
			}
			else {
				print(real(id), object_get_name(object_index), $"{hp}/{max_hp}", "was hit by", _amount, "from", _hitid, $"({object_get_name(other.object_index)})")
			}
		}
		
		return true
	}
	
	return false
}

/// @function scr_hit_self
/// @param amount
/// @param {Enum.HitId|Array} hitid=HitId.None
function scr_hit_self(_amount, _hitid = HitId.None) {
	gml_pragma("forceinline")
	return scr_hit(id, _amount, _hitid)
}

/// @function scr_projectile_hit
/// @param instance
/// @param amount
/// @param knockback_amount=0
/// @param knockback_direction=direction
function scr_projectile_hit(_instance, _amount, _kb_amount = 0, _kb_direction = undefined) {
	if _amount > 0 && scr_hit(_instance, _amount, hitid) {
		if _kb_amount != 0 {
			if is_undefined(_kb_direction) {
				_kb_direction = direction
			}
			
			with (_instance) motion_add(_kb_direction, _kb_amount)
		}
		
		return true
	}
	
	return false
}

/// @function scr_projectile_generic_hit
/// @param destroy=true
/// @param check_inframes=true
function scr_projectile_generic_hit(_destroy = true, _inframes = true) {
	if scr_can_hit(other.id, _inframes) && scr_projectile_hit(other.id, damage, knockback_speed) {
		if (_destroy) instance_destroy()
		return true
	}
	
	return false
}

/// @function scr_projectile_generic_bullet_hit
/// @param recycle_gland_yield=1
function scr_projectile_generic_bullet_hit(_gland = 1) {
	if scr_can_hit(other.id, false) && scr_projectile_hit(other.id, damage, knockback_speed) {
		if (instance_is(creator, Player) && scr_skill_get(mut_recycle_gland) && random(1) < 0.6) {
			with (creator) {
				scrPlayerGiveAmmo(id, Ammo.Bullets, _gland)
			}
			
			snd_play_hit(sndRecGlandProc)
			instance_create(x, y, RecycleGland)
		}
		
		instance_destroy()
		return true
	}
	
	return false
}

/// @function scr_projectile_generic_shell_hit
/// @param pointblank_bonus=1
function scr_projectile_generic_shell_hit(_bonus_amount = 1) {
	if scr_can_hit(other.id, false) {
		var _amount = damage + (bonus * _bonus_amount)
		
		if scr_projectile_hit(other.id, _amount, knockback_speed) {
			instance_destroy()
			return true
		}
	}
	
	return false
}

function scr_projectile_generic_plasma_hit() {
	// 接触类持续伤害按 30Hz 逻辑帧结算（同 laser，详见上）。
	// plasma 与目标持续重叠期间每物理帧命中一次：60 帧下「伤害 / 屏幕震动 / 收缩 / 反推」
	// 频率全部翻倍（实测：plasma ball 抖动频率过高、伤害同样过密）。
	// 门控后 60 帧 = 每 2 物理帧一次 → 与 30 帧真实时间一致；球体收缩步进也随之对齐
	//（60 帧下每 2 帧缩 0.1 → 存活帧数翻倍但真实时长与 30 帧相同）。
	// 30 帧 ts=1 → current_frame_active 恒真 → 行为逐帧不变。
	if (!current_frame_active) return false
	// 曾经在这里加「每 2 逻辑帧」的隔帧门控——**已撤销**：
	// 实测（10.17 NEW2b）30 帧的 plasma 对玩家/对道具都是「每 1 帧命中一次」（30/s），
	// 隔帧会把 60 帧砍成 15/s（半速），且每轮推进 2 逻辑帧只回退 1 物理帧 → 球会**穿过目标**。
	
	if scr_can_hit(other.id, false) {
		var _amount = floor(damage * (image_xscale + image_yscale) * 0.5)
		
		if scr_projectile_hit(other.id, _amount, knockback_speed) {
			instance_create(x, y, Smoke)
			snd_play(sndPlasmaHit)
			scr_screenshake(6)
			image_xscale -= 0.1
			image_yscale -= 0.1
			x -= hspeed
			y -= vspeed
			return true
		}
	}
	
	return false
}

/// @function scr_projectile_generic_grenade_hit
/// @param can_overkill_pierce=false
function scr_projectile_generic_grenade_hit(_pierce = false) {
	if scr_can_hit(other.id, false) {
		var _hp = other.hp
		if scr_projectile_hit(other.id, damage, knockback_speed) {
			if !_pierce || _hp > damage {
				instance_destroy()
			}
			
			return true
		}
	}
	
	return false
}

function scr_projectile_generic_flame_hit() {
	if scr_can_hit(other.id, true) {
		var _amount = damage
		
		if instance_is(other, Player) && scr_skill_get(mut_boiling_veins) {
			with other {
				if (hp - _amount) < veinsthreshold {
					_amount -= veinsthreshold - (hp - _amount)
				}
			}
		}
		
		return scr_hit(other.id, _amount, hitid)
	}
	
	return false
}

function scr_explosion_generic_hit() {
	if scr_can_hit(other.id, false) {
		var _amount = damage
		
		if instance_is(other, Player) && scr_skill_get(mut_boiling_veins) {
			with other {
				if (hp - _amount) < veinsthreshold {
					_amount -= veinsthreshold - (hp - _amount)
				}
			}
		}
		
		with (other) if (speed < (16) * timescale) {
			motion_add(point_direction(other.x, other.y, x, y), (6) * timescale)
			if (speed > (16) * timescale) speed = (16) * timescale
		}
		
		return scr_hit(other.id, _amount, hitid)
	}
	
	return false
}

function scr_projectile_generic_laser_hit() {
	// 接触类持续伤害按 30Hz 逻辑帧结算。
	// laser 光束在存活期间每物理帧都与目标重叠 → Collision_hitme 每帧命中一次；
	// 60 帧下命中频率翻倍（帧级伤害、非常密集）。门控后 = 每 2 物理帧结算一次，
	// 与 30 帧的「每逻辑帧一次」在真实时间上完全一致。
	// 30 帧 ts=1 → current_frame_active 恒真 → 行为逐帧不变（逐字节等价）。
	if (!current_frame_active) return false
	
	if scr_can_hit(other.id, false) && scr_projectile_hit(other.id, damage, knockback_speed) {
		with other {
			instance_create(bbox_center_x, bbox_center_y, Smoke)
		}
		
		return true
	}
	
	return false
}

/// @function scr_projectile_generic_bolt_hit
/// @param can_overkill_pierce=true
function scr_projectile_generic_bolt_hit(_pierce=true) {
	if speed == 0 && !check_wall_hit_damage {
		return false
	}
	
	if scr_can_hit(other.id, false) {
		var _hp_last = other.hp
		
		if (!scr_projectile_hit(other.id, damage, knockback_speed)) return false
		
		if !_pierce || _hp_last >= (damage * 0.5) {
			var _target = other.id
			
			with instance_create(x, y, BoltStick) {
				sprite_index = other.sprite_index
				image_index = sprite_get_number(sprite_index) - 1
				image_angle = other.image_angle
	            target = _target
			}
			
			var _direction = direction,
				_speed = knockback_speed * 0.8
			
			with (other) motion_add_m(_direction, _speed, (16) * timescale)
			
			instance_destroy()
		}
		else motion_add_m(direction, knockback_speed)
		
		return true
	}
	
	return false
}
