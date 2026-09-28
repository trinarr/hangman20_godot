extends RefCounted

const DESIGN = preload("res://scripts/core/game_design_config.gd")

# Return an index into the caller's remaining pool; never mark a preview as seen.
static func pick_index(candidates: Array, target: float, history: Dictionary, intro_active: bool, rng: RandomNumberGenerator, keys: Array, allow_harder_fallback: bool = false) -> int:
	if candidates.is_empty():
		return -1
	var window: float = DESIGN.get_float("difficulty.content_selection.initial_window", 0.04)
	var step: float = maxf(DESIGN.get_float("difficulty.content_selection.easier_step", 0.04), 0.001)
	var harder: float = DESIGN.get_float("difficulty.content_selection.intro_max_harder" if intro_active else "difficulty.content_selection.max_harder", 0.04 if intro_active else 0.08)
	var ceiling: float = minf(target + harder, 1.0)
	var counts: Dictionary = history.get("seen_count", {})
	var last: Dictionary = history.get("last_seen", {})
	var recent: Array = history.get("recent", [])
	var unseen: Array[int] = []
	var repeats: Array[int] = []
	for i: int in range(candidates.size()):
		var key: String = str(keys[i])
		if float(candidates[i].get("difficulty", 0.0)) > ceiling:
			continue
		if int(counts.get(key, 0)) == 0:
			unseen.append(i)
		else:
			repeats.append(i)
	var pool: Array[int] = []
	# First the comfortable window, then progressively easier unseen items.
	for i: int in unseen:
		if absf(float(candidates[i]["difficulty"]) - target) <= window:
			pool.append(i)
	if not pool.is_empty():
		return pool[rng.randi_range(0, pool.size() - 1)]
	var lower: float = maxf(0.0, target - window)
	while lower > 0.0:
		lower = maxf(0.0, lower - step)
		for i: int in unseen:
			var difficulty: float = float(candidates[i]["difficulty"])
			if difficulty >= lower and difficulty <= target:
				pool.append(i)
		if not pool.is_empty():
			return pool[rng.randi_range(0, pool.size() - 1)]
	# Slightly harder unseen items only after exhausting the easier side.
	var upper: float = target + minf(window, harder)
	while upper < ceiling:
		upper = minf(ceiling, upper + step)
		for i: int in unseen:
			if float(candidates[i]["difficulty"]) <= upper:
				pool.append(i)
		if not pool.is_empty():
			return pool[rng.randi_range(0, pool.size() - 1)]
	for i: int in repeats:
		var key: String = str(keys[i])
		if not recent.has(key):
			pool.append(i)
	if pool.is_empty() and not repeats.is_empty():
		# Tiny/exhausted pool: lift the cooldown for the oldest eligible item only.
		for key: Variant in recent:
			for i: int in repeats:
				if str(keys[i]) == str(key):
					return i
		pool = repeats
	if not pool.is_empty():
		var best: int = -1
		var best_count: int = 2147483647
		var best_seen: int = 9223372036854775807
		var best_distance: float = INF
		for i: int in pool:
			var key: String = str(keys[i])
			var count: int = maxi(int(counts.get(key, 1)), 1)
			var seen: int = int(last.get(key, 0))
			var distance: float = absf(float(candidates[i]["difficulty"]) - target)
			if count < best_count or (count == best_count and (seen < best_seen or (seen == best_seen and distance < best_distance))):
				best = i
				best_count = count
				best_seen = seen
				best_distance = distance
		return best
	# Content gap: no word at all fits the ceiling. Use the easiest available
	# word so the stage remains playable; never choose a harder word for novelty.
	if not allow_harder_fallback:
		return -1
	var easiest: int = 0
	for i: int in range(1, candidates.size()):
		if float(candidates[i]["difficulty"]) < float(candidates[easiest]["difficulty"]):
			easiest = i
	return easiest
