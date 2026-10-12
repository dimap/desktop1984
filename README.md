<h1 align="center">Desktop 1984</h1>

<p align="center">
  <a href="https://www.youtube.com/watch?v=6VsyN4ilMFE"><img src="demo/preview.gif" width="720" alt="Desktop 1984 in motion"></a>
</p>

<p align="center">
  <a href="https://www.youtube.com/watch?v=6VsyN4ilMFE">Full demo video</a> · <a href="README.ru.md">Русская версия</a>
</p>

An animated wallpaper for KDE Plasma 6. The camera glides at an angle over a
1-bit desktop whose every pixel is a tile floating above a plain gradient. The
tiles grow out of an empty background, the view drifts along a window or a row
of icons, and then it comes to rest as a still wallpaper.

The animation is inspired by the "Macintosh" wallpaper of macOS Sequoia. All
artwork here is original or comes from free KDE screenshots; see
[Licences](#licences).

## This project was made with AI!

This project was made with AI assistance. The code, the shader, the retro
desktop artwork and this documentation were written by Claude, an AI model by
Anthropic, working in Claude Code under the direction of the author, who set
the goals, made the design decisions and tested the result on a real desktop.

## Features

- **Four bundled pictures**: a retro desktop drawn for this wallpaper, and
  screenshots of KDE 1.1 (1999), KDE 2.2 (2001) and KDE 3.5 (2005) reduced to
  black and white.
- **Your own picture**: any PNG, JPEG, WebP, BMP, GIF or SVG file. It is scaled
  down and converted to black and white on the fly, with brightness, contrast
  and dithering under your control.
- **Still or moving**: by default the picture appears, glides to a halt and
  stays still, costing nothing afterwards. It can replay every few minutes, or
  run continuously like a screen saver.
- **Colors**: a spectrum that drifts through every hue while the picture moves,
  or one of seven fixed colors.
- **Adjustable look**: pixel size, gap, pixel opacity, shadow softness and
  strength, speed, and how the pixels appear.
- **Light on the GPU**: everything is drawn by one fragment shader; once the
  picture has come to rest nothing is redrawn.

## Requirements

- KDE Plasma 6
- Qt 6.4 or later

## Install

The package is ready to install as it is in this repository:

    kpackagetool6 --type Plasma/Wallpaper --install package

or, with `make` (this also rebuilds the shader and the pictures, see
[Building](#building)):

    make install

Then right-click the desktop, choose **Desktop and Wallpaper**, and pick
**Desktop 1984** as the wallpaper type.

After upgrading an installed copy, restart the shell so Plasma reloads it:

    systemctl --user restart plasma-plasmashell

To remove it:

    kpackagetool6 --type Plasma/Wallpaper --remove org.dimap.desktop1984

## Settings

### Picture

| Setting | What it does |
|---|---|
| **Picture** | One of the bundled pictures, or **Custom file…** |
| **File** | The image to use as a custom picture |
| **Width in pixels** | How many pixels across the custom picture is reduced to; fewer means chunkier |
| **Brightness**, **Contrast** | Tune the conversion of a custom picture to black and white |
| **Dither mid-tones** | Render greys as patterns of dots; off gives plain black and white |
| **Swap black and white** | Invert the picture; works for the bundled ones too |

Only dark pixels become tiles, so a picture with a light background works best.

### Animation and look

| Setting | What it does |
|---|---|
| **Color** | **Spectrum** drifts through all hues; the others are fixed |
| **Come to rest after appearing** | On: the picture appears, slows down and stays still. Off: scene follows scene without end |
| **Replay every** | When resting, sweep the picture away and show another scene this often |
| **Appearing** | From a wave that crosses the screen to all pixels growing at once |
| **Pixel size** | Size of one pixel on screen; **auto** fits about 122 across the screen |
| **Speed** | Speed of the whole animation |
| **Gap between pixels** | Space left between neighbouring tiles |
| **Pixel opacity** | How dark the tiles are against the background |
| **Shadow softness**, **Shadow strength** | Blur and darkness of the shadow under each tile |

## Preparing a picture by hand

The wallpaper converts custom pictures itself, but `tools/convert.py` gives
finer control and also sharpens outlines first. It writes a 1-bit PNG that the
wallpaper then shows unchanged:

    python3 tools/convert.py photo.jpg photo-1bit.png --width 480 --gamma 1.4

Run it with `--help` for the options. When using its output, set **Width in
pixels** to the width of the file.

## Building

Nothing needs building to install the wallpaper; the generated files are kept
in `package/`. To change the shader or the pictures you need:

- `qsb` from Qt Shader Tools, to compile the shader
- Python 3 with Pillow, to draw the retro desktop and convert the screenshots
- `qml` from Qt Declarative, for the preview and the demo
- `ffmpeg`, for the demo video

| Command | What it does |
|---|---|
| `make build` | Compiles the shader and regenerates the pictures |
| `make preview` | Shows the effect in a plain window, without Plasma |
| `make install` | Builds, then installs or upgrades the wallpaper for the current user |
| `make uninstall` | Removes it |
| `make demo` | Renders `demo/desktop1984-demo.mp4` and `demo/preview.gif` frame by frame |
| `make screenshots` | Renders the still pictures in `screenshots/` |
| `make dist` | Packs `dist/desktop1984-<version>.tar.gz`, the archive for store.kde.org |

Layout:

| Path | Contents |
|---|---|
| `package/` | The wallpaper itself, as installed |
| `package/contents/ui/PixelFlight.qml` | The animation: scenes, camera, timing |
| `package/contents/shaders/pixels.frag` | The shader that draws tiles, shadows and colors |
| `package/contents/ui/pictures.js` | The bundled pictures and their camera moves |
| `tools/gen_art.py` | Draws the retro desktop |
| `tools/convert.py` | Converts a picture to 1-bit |
| `tools/demo.qml` | Script of the demo video |

## Licences

Desktop 1984 is free software under the **GNU General Public License, version 2
or (at your option) any later version**. The full text is in [`LICENSE`](LICENSE).

| Files | Origin | Licence |
|---|---|---|
| Source code, shader, build scripts | Written for this project | GPL-2.0-or-later |
| `package/contents/images/world.png` | Original artwork, drawn by `tools/gen_art.py` | GPL-2.0-or-later |
| `package/contents/images/kde1.png` | 1-bit conversion of [KDE 1.1.jpg](https://commons.wikimedia.org/wiki/File:KDE_1.1.jpg), screenshot by the KDE development team | GPL |
| `package/contents/images/kde2.png` | 1-bit conversion of [KDE 2.2.2.png](https://commons.wikimedia.org/wiki/File:KDE_2.2.2.png), screenshot by the KDE development team | GPL |
| `package/contents/images/kde3.png` | 1-bit conversion of [KDE 3.5 screenshot.png](https://commons.wikimedia.org/wiki/File:KDE_3.5_screenshot.png), screenshot by Golradir | GPL |
| `tools/sources/*` | The unmodified screenshots above, from Wikimedia Commons | GPL |
| `tools/fonts/*.otb` | [Terminus Font](https://terminus-font.sourceforge.net/) by Dimitar Zhekov | SIL Open Font License 1.1, see `tools/fonts/OFL.txt` |
| `demo/*` | Recordings of this wallpaper showing the pictures above | GPL-2.0-or-later |

The KDE screenshots were sharpened and reduced to black and white with an
ordered dither; nothing else was changed. Terminus is used only to draw the
text of the retro desktop and is not part of the installed wallpaper.

The note in the retro desktop quotes Linus Torvalds.

The same information travels with the installed package in
[`package/CREDITS.md`](package/CREDITS.md).

### Trademarks

KDE and the K Desktop Environment logo are trademarks of KDE e.V. Macintosh and
macOS are trademarks of Apple Inc. This is an independent project: it contains
no artwork, fonts or code from Apple and is not affiliated with or endorsed by
Apple Inc. or KDE e.V.
