shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/button_shapes.gdshaderinc"

uniform vec2 body_size = vec2(100.0, 50.0);
uniform float padding = 6.0;
uniform bool round_shape = false;
uniform bool relief_pressed = false;
uniform vec4 face_tint : source_color = vec4(1.0);
uniform vec4 shadow_color : source_color = vec4(0.0);
uniform float shadow_offset = 0.0;

void fragment() {
 vec4 modulation = COLOR;
 vec2 p = UV * (body_size + vec2(padding * 2.0)) - vec2(padding) - body_size * 0.5;
 float d = button_distance(p, body_size, round_shape);
 float aa = max(fwidth(d) * 0.5, 0.0001);
 float coverage = 1.0 - smoothstep(-aa, aa, d);
 float depth = max(-d, 0.0);
 vec2 normal = button_edge_normal(p, body_size, round_shape);
 float h = min(body_size.x, body_size.y);
 float bevel = min(round_shape ? h * 0.09 : body_size.y * 0.10, h * 0.49);
 // Grayscale levels match the old neutral PNG masks before their palette tint:
 // normal face 209/255, pressed face 238/255, raised top / inset lower bevel.
 float interior = relief_pressed ? 0.933333 : 0.819608;
 float edge_light = relief_pressed
  ? 0.78 + 0.22 * max(normal.y, 0.0) - 0.08 * max(-normal.y, 0.0)
  : 0.62 + 0.38 * max(-normal.y, 0.0) - 0.09 * max(normal.y, 0.0);
 float rim = relief_pressed ? 0.41 : 0.34;
 float edge_shade = mix(rim, edge_light, smoothstep(0.0, h * 0.025, depth));
 float shade = mix(edge_shade, interior, smoothstep(bevel * 0.67, bevel, depth));
 float face_alpha = coverage * face_tint.a;
 float sd = button_distance(p - vec2(0.0, shadow_offset), body_size, round_shape);
 float shadow_aa = max(fwidth(sd) * 0.5, 0.0001);
 float shadow_alpha = (1.0 - smoothstep(-shadow_aa, shadow_aa, sd)) * shadow_color.a;
 // Composite the silhouette and face first, then apply inherited opacity once.
 float alpha = face_alpha + shadow_alpha * (1.0 - face_alpha);
 vec3 rgb = (face_tint.rgb * shade * face_alpha + shadow_color.rgb * shadow_alpha * (1.0 - face_alpha)) / max(alpha, 0.0001);
 COLOR = vec4(rgb, alpha) * modulation;
}
