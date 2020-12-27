/*
	CRT shader for Godot Engine by Yui Kinomoto @arlez80
*/
shader_type canvas_item;

const float PI = 3.1415926535;

// ブラウン管のガラスの曲がり具合（フラットなやつは0.0でいいかな）
uniform float crt_curve : hint_range( 0.0, 1.0 ) = 0.02;
// 走査線の濃さ
uniform float crt_scan_line_color : hint_range( 0.0, 1.0 ) = 0.347;
// 光量
uniform float crt_light_power = 1.0;
// RFスイッチ的ノイズ
uniform float rf_switch_esque_noise : hint_range( 0.0, 1.0 ) = 1.0;
// 白色ノイズ
uniform float white_noise_rate : hint_range( 0.0, 1.0 ) = 0.1;

float random( vec2 pos )
{ 
	return fract(sin(dot(pos, vec2(12.9898,78.233))) * 43758.5453);
}

void fragment( )
{
	// ガラスの曲がり具合
	float line_shift = sin( -UV.y * PI ) * crt_curve;
	float line_scale = 1.0 + line_shift * 2.0;
	vec2 fixed_uv = SCREEN_UV;
	fixed_uv.x = ( fixed_uv.x * line_scale ) - line_shift;

	// RFスイッチ的ノイズ
	COLOR = (
		(
			texture( SCREEN_TEXTURE, fixed_uv )
		*	( 1.0 - rf_switch_esque_noise * 0.5 )
		)
	+	(
			(
				texture( SCREEN_TEXTURE, fixed_uv + vec2( -SCREEN_PIXEL_SIZE.x * 3.1, 0.0 ) )
			+	texture( SCREEN_TEXTURE, fixed_uv + vec2( SCREEN_PIXEL_SIZE.x * 3.1, 0.0 ) )
			)
			*	( rf_switch_esque_noise * 0.25 )	// （RFノイズ）0.5 * （テクスチャから読んだ2箇所を半分にしたい）0.5
		)
	);
	COLOR.a = 1.0;

	// ------------------------------------------------
	// 以下はアパーチャグリル上の1ピクセルごとの処理
	vec2 aperture_grille_pixel = vec2( floor( ( SCREEN_UV.x / SCREEN_PIXEL_SIZE.x ) / 3.0 ) * 3.0, SCREEN_UV.y );

	// 白色ノイズ
	float white_noise = random( aperture_grille_pixel + vec2( TIME * 0.543254, TIME * 0.1563 ) );
	COLOR.rgb = mix(
		COLOR.rgb
	,	vec3( white_noise, white_noise, white_noise )
	,	white_noise_rate
	);

	// アパーチャグリル再現
	// int aperture_grille = int( ( ( SCREEN_UV.x * line_scale ) - line_shift ) / SCREEN_PIXEL_SIZE.x ) % 3;
	float aperture_grille_point = mod( ( ( SCREEN_UV.x * line_scale ) - line_shift ) / SCREEN_PIXEL_SIZE.x, 3.0 );
	float aperture_grille_r_rate = clamp( 1.0 - aperture_grille_point, 0.0, 1.0 ) + clamp( aperture_grille_point - 2.0, 0.0, 1.0 );
	float aperture_grille_g_rate = clamp( 1.0 - abs( 1.0 - aperture_grille_point ), 0.0, 1.0 );
	float aperture_grille_b_rate = 1.0 - aperture_grille_r_rate - aperture_grille_g_rate;
	COLOR = clamp(
		COLOR * vec4(
			normalize( vec3(
				aperture_grille_r_rate
			,	aperture_grille_g_rate
			,	aperture_grille_b_rate
			) )
		,	1.0
		) * crt_light_power
	,	vec4( 0.0, 0.0, 0.0, 0.0 )
	,	vec4( 1.0, 1.0, 1.0, 1.0 )
	);

	// 走査線
	COLOR = mix(
		COLOR
	,	vec4( 0.0, 0.0, 0.0, 1.0 )
	,	float( 0 == int( SCREEN_UV.y / SCREEN_PIXEL_SIZE.y ) % 2 ) * crt_scan_line_color
	);
}
