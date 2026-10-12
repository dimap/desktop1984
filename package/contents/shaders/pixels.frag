#version 440

// Draws the ink pixels of a 1-bit bitmap as dark tiles floating over a plain
// gradient, seen from an oblique camera. Tiles grow from nothing and shrink
// back in a wave that sweeps across the screen.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 resolution;   // item size, logical px
    vec2 texSize;      // bitmap size, cells
    vec2 center;       // bitmap point at the middle of the screen, cells
    vec4 toScreen;     // 2x2 matrix rows: cells -> logical px
    vec4 toPlane;      // its inverse: logical px -> cells
    vec2 ramp;         // sweep direction, bitmap space
    float appear;      // 0..1, sweep that grows the tiles
    float vanish;      // 0..1, sweep that shrinks them again
    float band;        // width of the sweep front, in screens: small is a sharp
                       //   wave, large has every tile growing at once
    float dpr;
    float gap;         // gap between tiles, fraction of a cell
    float tileOpacity; // how dark a tile is against the background, 0..1
    float shadowBlur;  // how far a shadow fades out past its tile, cells (up to 1)
    float shadowDepth; // how much the darkest part of a shadow darkens, 0..1
    float wrap;        // 1 repeats the bitmap past its edges, 0 leaves it empty there
    float gamma;       // picture to black and white: exponent on brightness,
    float contrast;    //   contrast around mid-grey,
    float dither;      //   1 for an ordered dither, 0 for a plain threshold,
    float invert;      //   1 swaps ink and paper
    vec4 colorTop;
    vec4 colorBottom;
};

layout(binding = 1) uniform sampler2D source;

vec2 mul(vec4 m, vec2 v)
{
    return vec2(dot(m.xy, v), dot(m.zw, v));
}

// The same hue and brightness with the weakest channel taken down to zero.
vec3 saturated(vec3 c)
{
    float hi = max(c.r, max(c.g, c.b));
    float lo = min(c.r, min(c.g, c.b));
    return hi - lo < 0.02 ? c : (c - lo) / (hi - lo) * hi;
}

float sweep(float progress, float u)
{
    return smoothstep(0.0, 1.0, (progress * (1.0 + band) - u) / band);
}

float bayer2(vec2 a)
{
    a = floor(a);
    return fract(a.x / 2.0 + a.y * a.y * 0.75);
}

// 4x4 ordered dither threshold for a cell, strictly between 0 and 1.
float bayer4(vec2 a)
{
    return bayer2(0.5 * a) * 0.25 + bayer2(a) + 1.0 / 32.0;
}

// 1 where the bitmap has an ink pixel. Pure black and white survive any
// setting untouched, so ready-made 1-bit pictures pass straight through.
float inkAt(vec2 cell)
{
    vec2 inside = step(vec2(0.0), cell) * step(cell, texSize - 1.0);
    float present = max(wrap, inside.x * inside.y);
    vec4 texel = texture(source, (mod(cell, texSize) + 0.5) / texSize);
    float luma = dot(texel.rgb, vec3(0.299, 0.587, 0.114)) + 1.0 - texel.a;
    luma = pow(clamp(luma, 0.0, 1.0), gamma);
    luma = clamp((luma - 0.5) * contrast + 0.5, 0.0, 1.0);
    float ink = step(luma, mix(0.5, bayer4(cell), dither));
    return present * mix(ink, 1.0 - ink, invert);
}

// How far the tile of a cell has grown: 0 is absent, 1 is full size.
float tileSize(vec2 cell)
{
    vec2 onScreen = mul(toScreen, cell + 0.5 - center);
    vec2 dir = normalize(mul(toScreen, ramp));
    float extent = dot(abs(dir), resolution);
    float u = dot(onScreen, dir) / extent + 0.5;
    return inkAt(cell) * sweep(appear, u) * (1.0 - sweep(vanish, u));
}

// Signed distance (in cells) from p to the tile of a cell grown to the given size.
float tileDistance(vec2 p, vec2 cell, float size)
{
    vec2 q = abs(p - cell - 0.5) - 0.5 * (1.0 - gap) * size;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

void main()
{
    vec2 p = center + mul(toPlane, (qt_TexCoord0 - 0.5) * resolution);

    // Width of one device pixel in cells, for antialiasing.
    float aa = max(length(toPlane.xy), length(toPlane.zw)) / dpr;
    vec2 here = floor(p);
    float size = tileSize(here);
    float cover = (1.0 - smoothstep(-0.5 * aa, 0.5 * aa, tileDistance(p, here, size)))
        * smoothstep(0.0, 0.02, size);

    // Soft shadow: the same tiles, shifted down the screen and blurred. Its
    // offset, blur and darkness all grow with the tile, so a tile that is
    // only starting to appear casts next to nothing.
    vec2 offset = mul(toPlane, vec2(0.0, 0.3) * length(toScreen.xz));
    vec2 base = floor(p - 0.5 * offset);
    float shadow = 0.0;
    for (int j = -1; j <= 1; ++j) {
        for (int i = -1; i <= 1; ++i) {
            vec2 cell = base + vec2(float(i), float(j));
            float grown = tileSize(cell);
            float blur = max(shadowBlur * grown, 1e-4);
            float d = tileDistance(p - offset * grown, cell, grown);
            shadow = max(shadow, grown * (1.0 - smoothstep(-0.3 * blur, blur, d)));
        }
    }

    vec3 bg = mix(colorTop.rgb, colorBottom.rgb, qt_TexCoord0.y);
    vec3 col = bg * (1.0 - shadowDepth * shadow);
    // Every tile has the same colour: the background at full saturation, darkened.
    vec3 tileColor = saturated(mix(colorTop.rgb, colorBottom.rgb, 0.5)) * (1.0 - tileOpacity);
    col = mix(col, mix(bg, tileColor, smoothstep(0.0, 0.08, tileOpacity)), cover);

    fragColor = vec4(col, 1.0) * qt_Opacity;
}
