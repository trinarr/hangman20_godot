extends Node
const LONG = preload("res://scripts/ui/stage_long_button.gd")
const ROUND = preload("res://scripts/ui/stage_round_button.gd")
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const BG := Color("#28345d")
var failures := 0
var checks := 0
func check(ok:bool,message:String)->void:
	checks+=1
	if !ok:failures+=1;push_error(message)
func _ready()->void:run.call_deferred()
func frame()->Image:
	for i in range(4):await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
func point(node:Control,local:Vector2)->Vector2i:
	return Vector2i((get_viewport().get_stretch_transform()*node.get_global_transform_with_canvas()*local).round())
func sample(image:Image,node:Control,local:Vector2)->Color:
	var p:=point(node,local)
	return image.get_pixel(p.x,p.y)
func near(a:Color,b:Color,tolerance:float=0.025)->bool:
	return maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))<=tolerance
func label(at:Vector2,text:String)->void:
	var l:=Label.new();l.position=at;l.text=text;l.add_theme_font_override("font",FONTS.regular_font());l.add_theme_font_size_override("font_size",20);add_child(l)
func button(circle:bool,at:Vector2,extent:Vector2,preset:int=0)->Control:
	var b:Control=ROUND.new() if circle else LONG.new()
	b.use_stage_layout=false;b.stage_rect=Rect2(at,extent);add_child(b);b.set_color_preset(preset)
	check(b._background.visible and b._background.material.get_shader_parameter("body_size")==extent,"Background is configured before first draw")
	return b
func run()->void:
	if DisplayServer.get_name()=="headless":get_tree().quit(1);return
	var background:=ColorRect.new();background.color=BG;background.size=Vector2(960,2200);add_child(background)
	label(Vector2(40,8),"Procedural button palettes and states")
	var buttons:Array[Control]=[]
	var titles=["Orange","Green","Blue","Pressed","Selected","Disabled"]
	for i in range(6):
		var y:=55+i*112
		var b:=button(false,Vector2(520,y),Vector2(360,76),i if i<3 else 0)
		if i==3:b._is_down=true
		if i==4:b.selected=true
		if i==5:b.button_disabled=true
		b.queue_redraw()
		buttons.append(b)
		label(Vector2(410,y+18),titles[i])
	for i in range(4):
		var x:=40+i*220
		var b:=button(true,Vector2(x,910),Vector2(124,124),i%3)
		if i==1:b._is_down=true
		if i==2:b.selected=true
		if i==3:b.button_disabled=true;b.disabled_visual_opacity=1.0
		b.queue_redraw()
		buttons.append(b)
	label(Vector2(40,1055),"Round button states")
	var shadowed:=button(false,Vector2(40,1130),Vector2(350,80));shadowed.drop_shadow_enabled=true
	var round_shadow:=button(true,Vector2(440,1120),Vector2(110,110));round_shadow.drop_shadow_enabled=true
	var short:=button(false,Vector2(660,1130),Vector2(120,60),2)
	var first:=await frame()
	var preview_dir := OS.get_environment("HANGMAN_BUTTON_PREVIEW_DIR")
	if !preview_dir.is_empty():
		check(first.save_png(preview_dir.path_join("procedural-buttons-comparison-%d.png" % get_window().size.x))==OK,"Comparison screenshot saved")
	for b:Control in buttons:
		var tint: Color = b.normal_tint
		if b.disabled:
			tint = Color(b.DISABLED_TINT.r,b.DISABLED_TINT.g,b.DISABLED_TINT.b,1.0)
		elif b.selected:tint = b.selected_tint
		elif b._is_down:tint = b.pressed_tint
		var shade := 238.0/255.0 if b.selected or b._is_down or b.disabled else 209.0/255.0
		var expected := Color(tint.r*shade,tint.g*shade,tint.b*shade,1.0)
		check(near(sample(first,b,b.size*0.5),expected),"Face palette retains calibrated neutral relief: "+str(b.position))
		check(near(sample(first,b,Vector2(0,0)),BG),"Transparent exterior corners")
		check(b._background.material is ShaderMaterial and b._background.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Shader background cannot intercept input")
		check(b._background.show_behind_parent,"Background stays behind captions, icons and shine")
	check(!near(sample(first,shadowed,Vector2(175,82)),BG),"Long shadow remains visible outside face")
	check(!near(sample(first,round_shadow,Vector2(55,112)),BG),"Round shadow remains visible outside face")
	check(!near(sample(first,short,short.size*0.5),BG),"Short capsule renders without slice joins")
	var orange:Control=buttons[0];var blue:Control=buttons[2]
	orange.modulate.a=0.5
	shadowed.modulate.a=0.5
	var faded:=await frame()
	check(near(sample(faded,orange,orange.size*0.5),BG.lerp(sample(first,orange,orange.size*0.5),0.5)),"Whole button respects inherited half-opacity")
	check(near(sample(faded,shadowed,Vector2(175,82)),BG.lerp(sample(first,shadowed,Vector2(175,82)),0.5)),"Shadow respects inherited half-opacity")
	orange.modulate.a=1.0;orange.visual_scale=Vector2(0.94,0.94)
	var pressed:=await frame()
	check(near(sample(pressed,orange,Vector2(2,orange.size.y*0.5)),BG),"Press shrinks background about button center")
	check(near(sample(pressed,orange,orange.size*0.5),sample(first,orange,orange.size*0.5)),"Press preserves face center")
	check(!near(sample(pressed,orange,Vector2(16,orange.size.y*0.5)),BG),"Press applies visual scale once, not twice")
	orange.visual_scale=Vector2.ONE
	orange.normal_tint=Color(0.8,0.1,0.7)
	var recolored:=await frame()
	check(!near(sample(recolored,orange,orange.size*0.5),sample(first,orange,orange.size*0.5)),"Instance recolors independently")
	check(near(sample(recolored,blue,blue.size*0.5),sample(first,blue,blue.size*0.5)),"Other instance retains palette")
	orange._configure_attention_shine(0.16,0.42);orange._set_attention_shine_progress(0.6)
	var shining:=await frame()
	check(sample(shining,orange,orange.size*0.5).g>sample(recolored,orange,orange.size*0.5).g+0.05,"Attention shine is above procedural face")
	check(near(sample(shining,orange,Vector2(1,1)),BG),"Attention shine shares capsule contour")
	short.size=Vector2(210,90)
	var resized:=await frame()
	check(short._background.material.get_shader_parameter("body_size")==short.size,"Shader follows live resize")
	check(!near(sample(resized,short,short.size*0.5),BG),"Resized capsule stays filled")
	print("PROCEDURAL_BUTTONS_RENDER checks=",checks," failures=",failures)
	get_tree().quit(1 if failures else 0)
