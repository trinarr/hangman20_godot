extends Node
## Run with a real renderer. Compare restored UI with the original hinted font.
const FONTS = preload("res://scripts/ui/ui_fonts.gd")
const STYLE = preload("res://scripts/ui/button_text_style.gd")
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if !ok:
  failures += 1
  push_error(message)
func _ready() -> void:
 run.call_deferred()
func frame() -> Image:
 for _i in range(4):await get_tree().process_frame
 await RenderingServer.frame_post_draw
 return get_viewport().get_texture().get_image()
func reference(profile: FontVariation) -> FontVariation:
 var result := FontVariation.new()
 var source := load("res://fonts/RobotoFlex-Variable.ttf").duplicate() as FontFile
 source.multichannel_signed_distance_field = false
 source.hinting = TextServer.HINTING_LIGHT
 result.base_font = source
 result.variation_opentype = profile.variation_opentype.duplicate()
 return result
func score(image: Image, area: Rect2i) -> float:
 var value := 0.0
 for y in range(maxi(area.position.y,0),mini(area.end.y,image.get_height())):
  for x in range(maxi(area.position.x,0),mini(area.end.x,image.get_width())):
   value += image.get_pixel(x,y).r
 return value
func run() -> void:
 if DisplayServer.get_name() == "headless":
  push_error("Raster UI regression requires a real renderer")
  get_tree().quit(1)
  return
 var background := ColorRect.new()
 background.size = get_viewport().get_visible_rect().size
 background.color = Color.BLACK
 add_child(background)
 var stage := Control.new()
 stage.scale = Vector2(2,2)
 add_child(stage)
 var profiles: Array[FontVariation] = [FONTS.regular_font(), FONTS.question_comment_font(),
  FONTS.word_input_caption_font(), FONTS.regular_font(700.0),
  FONTS.button_font_raster(), FONTS.display_font_raster()]
 var copy := ["с c G Э 469 Ы Й ё", "Шоколадная марка с девочкой в платке на обертке.",
  "Введите слово / G", "НОВАЯ / NEW", "ВКЛ ВЫКЛ ON OFF", "Турнир 07:59:59"]
 var sizes := [17,25,28,12,21,18]
 var labels: Array[Label] = []
 for i in range(profiles.size()):
  var font: FontVariation = profiles[i]
  check(!font.base_font.multichannel_signed_distance_field, "Small/body profile uses raster: %d" % i)
  check(font.base_font.hinting == TextServer.HINTING_LIGHT, "Small/body profile uses hinting: %d" % i)
  var label := Label.new()
  label.position = Vector2(24,12+i*84)
  label.size = Vector2(400,72)
  label.text = copy[i]
  label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  label.add_theme_font_override("font",font)
  label.add_theme_font_size_override("font_size",sizes[i])
  stage.add_child(label)
  if i<4:STYLE.apply_regular_display(label)
  else:STYLE.apply_display(label)
  labels.append(label)
 var bold := Label.new()
 bold.position = Vector2(24,530)
 bold.size = Vector2(380,64)
 bold.text = "НОВАЯ"
 bold.add_theme_font_override("font",FONTS.regular_font(700.0))
 bold.add_theme_font_size_override("font_size",32)
 stage.add_child(bold)
 var rendered := await frame()
 for i in range(labels.size()):labels[i].add_theme_font_override("font",reference(profiles[i]))
 var expected := await frame()
 check(rendered.get_data() == expected.get_data(), "Styled UI matches original hinted variable-font rendering")
 var transform := get_viewport().get_stretch_transform() * bold.get_global_transform_with_canvas()
 var area := Rect2i(transform * Rect2(Vector2.ZERO,bold.size))
 bold.add_theme_font_override("font",FONTS.regular_font())
 var lighter := await frame()
 check(score(rendered,area)>score(lighter,area)+0.5, "Weight 700 changes visible NEW badge strokes compared with 650")
 var ts := TextServerManager.get_primary_interface()
 check(FONTS.regular_font().variation_opentype[ts.name_to_tag("wght")] == 650.0, "NEW weight does not mutate regular copy")
 check(FONTS.regular_font(700.0) == FONTS.regular_font(700.0), "Weighted raster profiles are cached")
 check(FONTS.button_font() != FONTS.button_font_raster(), "Raster and MSDF profiles have separate caches")
 check(FONTS.button_font().spacing_glyph == 0 and FONTS.button_font_raster().spacing_glyph == 0, "Compact native spacing is preserved")
 for width in range(25,36):
  check(FONTS.display_font_with_width(width).base_font.multichannel_signed_distance_field, "Heading remains MSDF at width %d" % width)
 check(FONTS.button_font().base_font.multichannel_signed_distance_field, "Large button captions retain MSDF")
 check(!FONTS.gameplay_word_font().base_font.multichannel_signed_distance_field, "Gameplay word letters retain raster")
 print("FONT_RASTER_UI_RENDER checks=",checks," failures=",failures)
 get_tree().quit(1 if failures else 0)
