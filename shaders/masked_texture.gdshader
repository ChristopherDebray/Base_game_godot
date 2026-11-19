shader_type canvas_item;

// Masque de visibilité (rendu du `VisibilityViewport`) : noir = visible, blanc = caché.
// Filtre linéaire sur le masque seulement, pour que le flou interpole entre ses pixels.
uniform sampler2D mask_texture : filter_linear;
// Visibilité (1 - mask.r) à partir de laquelle un pixel est montré. La lumière du joueur
// n'éteint jamais complètement le masque : un seuil évite que tout soit semi-transparent.
uniform float visibility_threshold : hint_range(0.0, 1.0) = 0.5;
// Demi-largeur du fondu autour du seuil : 0 donne un bord net, plus grand un bord plus doux.
uniform float edge_softness : hint_range(0.0, 0.5) = 0.1;
// Écart (en pixels du masque) entre les échantillons du flou. Le bord du masque est en escalier
// (texture du cône, ombres) : le flouter lisse le bord de vision. 0 désactive le flou.
uniform float mask_blur_radius : hint_range(0.0, 8.0) = 2.0;

// Moyenne 3x3 du masque autour de `uv`, convertie en visibilité (1 = visible).
float sample_visibility(vec2 uv) {
	vec2 sample_step = mask_blur_radius / vec2(textureSize(mask_texture, 0));
	float mask_sum = 0.0;
	for (int offset_x = -1; offset_x <= 1; offset_x++) {
		for (int offset_y = -1; offset_y <= 1; offset_y++) {
			mask_sum += texture(mask_texture, uv + vec2(float(offset_x), float(offset_y)) * sample_step).r;
		}
	}
	return 1.0 - mask_sum / 9.0;
}

void fragment() {
	float visibility = sample_visibility(UV);
	// smoothstep exige edge0 < edge1 : on garde une largeur minimale pour le bord net.
	float softness = max(edge_softness, 0.001);
	float reveal = smoothstep(visibility_threshold - softness, visibility_threshold + softness, visibility);
	// On module l'alpha d'origine au lieu de l'écraser : les zones transparentes du LitViewport
	// restent transparentes, et l'intérieur du cône reste opaque.
	COLOR.a *= reveal;
}
