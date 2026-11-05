extends Node
const EXTRUSION = preload("res://scripts/ui/portrait_icon_extrusion.gd")
const MATERIALS = preload("res://scripts/ui/ui_materials.gd")
const FADE = preload("res://scripts/ui/composited_fade.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if !ok:
		failures += 1
		push_error(message)
func _ready() -> void:
	run.call_deferred()
func _process(_delta: float) -> void:
	if OS.get_environment("HANGMAN_TEST_HIDE_WINDOW") == "1": RenderingServer.force_draw(false)
func frames() -> void:
	for i in range(3): await get_tree().process_frame
	await RenderingServer.frame_post_draw
func old_shadow(parent: Node, texture: Texture2D, width: float) -> void:
	var material := MATERIALS.icon_shadow(Color(.05,.08,.24,.5),width)
	for t: float in [.25,.55,.8,1.0]:
		var layer := TextureRect.new()
		layer.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;layer.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		layer.texture=texture;layer.size=Vector2(96,72);layer.position=Vector2(.864,3.96)*t
		layer.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;layer.material=material
		parent.add_child(layer)
func image_error(a: Image, b: Image) -> float:
	var da:=a.get_data();var db:=b.get_data();var error:=0.0;var count:=0
	for i in range(0,da.size(),4):
		if da[i+3]>0 or db[i+3]>0:
			error+=absf(float(da[i+3])-float(db[i+3]))/255.0
			count+=1
	return error/maxi(count,1)
func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Combined shadow regression requires GPU");get_tree().quit(1);return
	var vp:=SubViewport.new();vp.size=Vector2i(384,384);vp.transparent_bg=true
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var source:=Image.create(64,32,false,Image.FORMAT_RGBA8)
	source.fill(Color.TRANSPARENT);source.fill_rect(Rect2i(12,4,40,24),Color.WHITE)
	var wide:=ImageTexture.create_from_image(source)
	var textures: Array[Texture2D]=[load("res://flash_assets/star_currency_icon.png"),wide]
	for ratio: float in [1.0,1.5]:
		vp.size=Vector2i.ONE*roundi(256*ratio);vp.size_2d_override=Vector2i(256,256);vp.size_2d_override_stretch=true
		for texture in textures:
			for width: float in [0.0,5.0,8.0]:
				for zoom: float in [.8,1.2]:
					for opacity: float in [1.0,.5,0.0]:
						var ref:=Control.new();ref.position=Vector2(64,64);ref.scale=Vector2.ONE*zoom;ref.modulate.a=opacity
						vp.add_child(ref);old_shadow(ref,texture,width)
						await frames();var baseline:=vp.get_texture().get_image();ref.free()
						var holder:=Control.new();holder.position=Vector2(64,64);holder.scale=Vector2.ONE*zoom;holder.modulate.a=opacity
						vp.add_child(holder)
						var layers:=EXTRUSION._create_portrait_icon_extrusion_layers(holder,texture,"Test",0,.5)
						EXTRUSION.set_shadow_material(layers,MATERIALS.icon_shadow(Color(.05,.08,.24,.5),width))
						EXTRUSION._layout_portrait_icon_extrusion_layers(layers,Vector2.ZERO,Vector2(96,72))
						# Freeze an intermediate tween value before drawing: the mask must follow in this frame.
						await frames();var actual:=vp.get_texture().get_image()
						var captures := "user://" if OS.has_feature("android") else OS.get_environment("HANGMAN_UI_CAPTURE_DIR")
						if !captures.is_empty() and ratio==1 and width==0 and zoom==.8 and opacity==1 and texture==textures[0]:
							baseline.save_png(captures.path_join("combined_shadow_small_reference.png"))
							actual.save_png(captures.path_join("combined_shadow_small_direct.png"))
						if !captures.is_empty() and ratio==1.5 and width==5 and zoom==1.2 and opacity==1 and texture==textures[0]:
							baseline.save_png(captures.path_join("combined_shadow_reference.png"))
							actual.save_png(captures.path_join("combined_shadow_cached.png"))
						var error:=image_error(baseline,actual)
						check(error < (.012 if width==0 else .06),"Shadow alpha matches four passes: width=%s zoom=%s opacity=%s ratio=%s error=%s" %[width,zoom,opacity,ratio,error])
						if opacity==0:check(!actual.get_used_rect().has_area(),"Zero alpha removes every shadow pixel")
						if width>0:
							check(layers[0].material.get_shader_parameter("use_mask")==true,"Outlined shadow uses bounded mask")
						else:check(layers[0].get("_entry").is_empty(),"Unoutlined shadow allocates no mask")
						holder.free()
	await check_button_pivots(vp,textures[0])
	await check_material_reset(textures[0])
	await check_viewport_reentry(textures[0])
	# Sharing, independent materials, tween updates and release on reparent/exit.
	var holder:=Control.new();vp.add_child(holder)
	var layers:=EXTRUSION._create_portrait_icon_extrusion_layers(holder,textures[0],"Shared",0,.5)
	EXTRUSION._layout_portrait_icon_extrusion_layers(layers,Vector2.ZERO,Vector2.ONE*96)
	EXTRUSION.set_shadow_material(layers,MATERIALS.icon_shadow(Color(.05,.08,.24,.5),5))
	var other:=EXTRUSION._create_portrait_icon_extrusion_layers(holder,textures[0],"Other",0,.5)
	EXTRUSION._layout_portrait_icon_extrusion_layers(other,Vector2.ZERO,Vector2.ONE*96)
	EXTRUSION.set_shadow_material(other,MATERIALS.icon_shadow(Color(.05,.08,.24,.5),5))
	await frames()
	check(layers[0].get("_entry")==other[0].get("_entry") and layers[0].material!=other[0].material,"Same mask shared, per-icon uniforms independent")
	var cache: Node=layers[0].get("_cache")
	var previous: Array=layers[0].get("_key").duplicate()
	var tween:=holder.create_tween();tween.tween_property(holder,"scale",Vector2.ONE*1.2,.15)
	await get_tree().create_timer(.08).timeout;await RenderingServer.frame_post_draw
	check(layers[0].get("_key")!=previous,"Tween intermediate scale changes mask key before draw")
	await tween.finished;await frames()
	check(layers[0].get("_key")[1].distance_to(Vector2.ONE*96*1.2*1.5)<.02,"Final mask uses physical viewport scale")
	FADE.branch(holder);FADE.set_opacity(holder,.5);await frames()
	check(layers[0].self_modulate.a<1.0,"Fade branch drives combined shadow")
	FADE.set_opacity(holder,0);await frames()
	check(!vp.get_texture().get_image().get_used_rect().has_area(),"Composited zero removes both combined shadows")
	FADE.set_opacity(holder,1);await frames()
	var moved: TextureRect=layers[0];moved.reparent(self);await frames()
	check(other[0].get("_entry").users==1,"Reparent releases old mask ownership")
	moved.free();holder.free();await frames()
	for i in range(80):
		var entry: Dictionary=cache.acquire(textures[0],Vector2.ONE*(80+i*5),5)
		cache.release(entry)
	check(cache.allocated_bytes<=cache.MAX_BYTES and cache.entries.size()<=cache.MAX_ENTRIES,"Mask cache stays bounded across changing sizes")
	var oversized: Dictionary=cache.acquire(textures[0],Vector2.ONE*4096,8)
	check(oversized.is_empty(),"Oversize request uses allocation-free shader fallback")
	for entry: Dictionary in cache.entries:check(entry.users==0,"Removed nodes release mask users")
	var blocker: Dictionary=cache.acquire(textures[0],Vector2.ONE*500,5)
	check(!blocker.is_empty(),"Budget fixture retains one full-capacity active mask")
	var fallback_holder:=Control.new();fallback_holder.position=Vector2(64,64);vp.add_child(fallback_holder)
	var fallback_layers:=EXTRUSION._create_portrait_icon_extrusion_layers(fallback_holder,textures[0],"Fallback",0,.5)
	EXTRUSION.set_shadow_material(fallback_layers,MATERIALS.icon_shadow(Color(.05,.08,.24,.5),5))
	EXTRUSION._layout_portrait_icon_extrusion_layers(fallback_layers,Vector2.ZERO,Vector2(96,72))
	await frames()
	check(fallback_layers[0].material.get_shader_parameter("use_mask")==false,"Full budget selects shader fallback")
	var fallback_image:=vp.get_texture().get_image();fallback_holder.free()
	var fallback_reference:=Control.new();fallback_reference.position=Vector2(64,64);vp.add_child(fallback_reference)
	old_shadow(fallback_reference,textures[0],5);await frames()
	check(image_error(fallback_image,vp.get_texture().get_image())<.012,"Fallback preserves original four-pass alpha")
	fallback_reference.free();cache.release(blocker)
	vp.free();await frames()
	print("COMBINED_ICON_SHADOW_RENDER checks=%d failures=%d" %[checks,failures])
	get_tree().quit(1 if failures else 0)

func check_material_reset(texture: Texture2D) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(192,192)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var holder := Control.new()
	holder.position = Vector2(32,32)
	viewport.add_child(holder)
	var layers := EXTRUSION._create_portrait_icon_extrusion_layers(holder,texture,"Reset",0,.5)
	EXTRUSION._layout_portrait_icon_extrusion_layers(layers,Vector2.ZERO,Vector2(96,72))
	var plain := MATERIALS.icon_shadow(Color(.05,.08,.24,.5))
	EXTRUSION.set_shadow_material(layers,plain)
	await frames()
	var baseline := viewport.get_texture().get_image()
	for cycle in range(2):
		EXTRUSION.set_shadow_material(layers,MATERIALS.icon_shadow(Color(.05,.08,.24,.5),5))
		await frames()
		check(layers[0].material.get_shader_parameter("use_mask") == true,"Outlined material acquires a mask before reset")
		EXTRUSION.set_shadow_material(layers,plain)
		await frames()
		check(layers[0].material.get_shader_parameter("colored_outline") == false and layers[0].material.get_shader_parameter("outline_pixels") == 2.0,"Plain material restores source shader defaults after outlined style")
		check(layers[0]._entry.is_empty() and layers[0].material.get_shader_parameter("use_mask") == false,"Reset releases the previous outline mask")
		check(image_error(baseline,viewport.get_texture().get_image()) < .001,"Reset restores the original unoutlined pixels")
	viewport.free()

func check_viewport_reentry(texture: Texture2D) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(192,192)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var holder := Control.new()
	holder.position = Vector2(32,32)
	viewport.add_child(holder)
	var layers := EXTRUSION._create_portrait_icon_extrusion_layers(holder,texture,"Reentry",0,.5)
	EXTRUSION.set_shadow_material(layers,MATERIALS.icon_shadow(Color(.05,.08,.24,.5),5))
	EXTRUSION._layout_portrait_icon_extrusion_layers(layers,Vector2.ZERO,Vector2(96,72))
	await frames()
	var baseline := viewport.get_texture().get_image()
	var cache: Node = layers[0]._cache
	for cycle in range(3):
		var old_mask: WeakRef = weakref(layers[0]._entry.viewport)
		remove_child(viewport)
		check(old_mask.get_ref() == null and cache.get_child_count() == 0 and cache.entries.is_empty() and cache.allocated_bytes == 0,"Viewport exit frees masks and clears all allocation accounting")
		add_child(viewport)
		await frames()
		check(cache.get_child_count() == 1 and cache.entries.size() == 1 and cache.allocated_bytes == cache.entries[0].bytes,"Viewport reentry retains exactly one accounted mask")
		check(layers[0]._entry.users == 1 and layers[0].material.get_shader_parameter("use_mask") == true,"Reentered consumer reacquires its mask")
		check(image_error(baseline,viewport.get_texture().get_image()) < .001,"Viewport reentry restores shadow pixels")
	viewport.free()

func check_button_pivots(viewport: SubViewport, texture: Texture2D) -> void:
	for width: float in [0.0,5.0]:
		for zoom: float in [.94,1.1]:
			var original:=FlashStageTextureButton.new()
			original.use_stage_layout=false;original.press_scale_enabled=true
			original.stage_rect=Rect2(64,64,150,100)
			viewport.add_child(original)
			old_shadow(original,texture,width)
			original.visual_scale=Vector2.ONE*zoom
			await frames()
			var baseline:=viewport.get_texture().get_image()
			original.free()
			var button:=FlashStageTextureButton.new()
			button.use_stage_layout=false;button.press_scale_enabled=true
			button.stage_rect=Rect2(64,64,150,100)
			viewport.add_child(button)
			var layers:=EXTRUSION._create_portrait_icon_extrusion_layers(button,texture,"Press",0,.5)
			EXTRUSION.set_shadow_material(layers,MATERIALS.icon_shadow(Color(.05,.08,.24,.5),width))
			EXTRUSION._layout_portrait_icon_extrusion_layers(layers,Vector2.ZERO,Vector2(96,72))
			button.visual_scale=Vector2.ONE*zoom
			await frames()
			var actual:=viewport.get_texture().get_image()
			if width==0 and zoom==.94:
				baseline.save_png("user://press_reference.png")
				actual.save_png("user://press_combined.png")
				if !OS.get_environment("HANGMAN_UI_CAPTURE_DIR").is_empty():
					baseline.save_png(OS.get_environment("HANGMAN_UI_CAPTURE_DIR").path_join("press_reference.png"))
					actual.save_png(OS.get_environment("HANGMAN_UI_CAPTURE_DIR").path_join("press_combined.png"))
			var error:=image_error(baseline,actual)
			check(error<(.012 if width==0 else .06),"Button shared pivot preserves shadow at visual_scale=%s width=%s error=%s bounds=%s/%s" %[zoom,width,error,baseline.get_used_rect(),actual.get_used_rect()])
			button.free()
