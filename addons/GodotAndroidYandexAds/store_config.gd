@tool
extends RefCounted
## Public store-specific ad configuration; never fall back to another store.

const PROFILE_PATH := "res://data/ad_store_profiles.json"
const STORES: Array[String] = ["rustore", "google_play"]

static func store_from_features(features: PackedStringArray) -> String:
	var selected: String = ""
	for store: String in STORES:
		if features.has(store):
			if !selected.is_empty():
				return ""
			selected = store
	return selected

static func runtime_store() -> String:
	var features := PackedStringArray()
	for store: String in STORES:
		if OS.has_feature(store):
			features.append(store)
	return store_from_features(features)

static func profile(store: String) -> Dictionary:
	if !STORES.has(store):
		return {}
	var profiles: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROFILE_PATH))
	if profiles is Dictionary and profiles.get(store) is Dictionary:
		return profiles[store]
	return {}
