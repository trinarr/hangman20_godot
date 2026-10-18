// Analytic circle/capsule shared by the face and attention-shine masks.
float button_distance(vec2 p, vec2 extent, bool round_shape) {
 float radius = min(extent.x, extent.y) * 0.5;
 vec2 reach = round_shape ? vec2(0.0) : max(extent * 0.5 - vec2(radius), vec2(0.0));
 return length(p - clamp(p, -reach, reach)) - radius;
}
vec2 button_edge_normal(vec2 p, vec2 extent, bool round_shape) {
 float radius = min(extent.x, extent.y) * 0.5;
 vec2 reach = round_shape ? vec2(0.0) : max(extent * 0.5 - vec2(radius), vec2(0.0));
 vec2 delta = p - clamp(p, -reach, reach);
 return delta / max(length(delta), 0.0001);
}
