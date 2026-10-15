// 60帧适配：与 alarm[0] 等价的按 timescale 计时兜底，
// 确保「变异选择提示文字」无论如何都会进入消失阶段（详见 Create_0.gml）。
if (!disappear) {
    showtime += timescale
    if (showtime >= 40) disappear = 10
}

if disappear {
    disappear -= timescale

    if (disappear <= 0) {
		instance_destroy()
	}
}

if lockstep_stop
	exit