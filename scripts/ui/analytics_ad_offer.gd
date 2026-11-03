extends Node
## Owned by the offer button; stops observing after its first visible opportunity.
var placement: String = ""
var scope: String = ""

func _process(_delta: float) -> void:
	var button := get_parent() as Control
	if button == null or !button.is_visible_in_tree() or !Analytics._enabled:
		return
	var disabled: Variant = button.get("disabled") if button is BaseButton else button.get("button_disabled")
	if disabled == true or button.get_global_rect().intersection(button.get_viewport_rect()).has_area() == false:
		return
	var ancestor: Node = button
	while ancestor is CanvasItem:
		if ancestor.modulate.a <= 0.01 or ancestor.self_modulate.a <= 0.01:
			return
		if ancestor.has_meta(&"composited_branch"):
			var controller: Node = ancestor.get_meta(&"composited_branch").get_ref()
			if is_instance_valid(controller) and controller.opacity <= 0.01:
				return
		if ancestor is Control and ancestor.clip_contents and !ancestor.get_global_rect().intersects(button.get_global_rect()):
			return
		ancestor = ancestor.get_parent()
	Analytics.track_once("offer:%s:%s" % [scope, placement], "ad_offer_shown", {"placement": placement, "ad_format": "rewarded"})
	set_process(false)
