PKG := package
ID := org.dimap.desktop1984
SHADER := $(PKG)/contents/shaders/pixels.frag

VERSION := $(shell python3 -c "import json; print(json.load(open('$(PKG)/metadata.json'))['KPlugin']['Version'])")
DIST := dist/desktop1984-$(VERSION).tar.gz

.PHONY: build art preview demo screenshots dist install uninstall

build: $(SHADER).qsb art

$(SHADER).qsb: $(SHADER)
	qsb-qt6 --qt6 -o $@ $<

IMAGES := $(PKG)/contents/images

art:
	python3 tools/gen_art.py
	python3 tools/convert.py tools/sources/kde1.jpg $(IMAGES)/kde1.png --gamma 1.2
	python3 tools/convert.py tools/sources/kde2.png $(IMAGES)/kde2.png --gamma 1.4
	python3 tools/convert.py tools/sources/kde3.png $(IMAGES)/kde3.png --gamma 1.4

preview: build
	qml-qt6 preview.qml

# Renders the demo video and the README preview cut from it. Opens a window
# for a couple of minutes while it renders the frames.
demo: build
	rm -rf build/frames && mkdir -p build/frames demo
	qml-qt6 tools/demo.qml
	ffmpeg -v error -y -framerate 30 -i build/frames/%05d.jpg -vf scale=1920:1080:flags=lanczos \
		-c:v libx264 -crf 20 -preset slow -pix_fmt yuv420p -movflags +faststart demo/desktop1984-demo.mp4
	ffmpeg -v error -y -i demo/desktop1984-demo.mp4 -filter_complex "\
		[0:v]trim=0:8,setpts=PTS-STARTPTS[a];[0:v]trim=16:24,setpts=PTS-STARTPTS[b];\
		[0:v]trim=32:42.5,setpts=PTS-STARTPTS[c];[a][b][c]concat=n=3:v=1,fps=12,\
		scale=640:-1:flags=lanczos,split[x][y];[x]palettegen=max_colors=128:stats_mode=diff[p];\
		[y][p]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle" demo/preview.gif

# Still pictures for the store page. Opens a window for a few seconds.
screenshots: build
	mkdir -p screenshots
	qml-qt6 tools/screenshots.qml
	python3 -c "import glob; from PIL import Image; \
		[Image.open(f).convert('RGB').resize((1920, 1080), Image.LANCZOS).save(f, optimize=True) \
		for f in glob.glob('screenshots/*.png')]"

# The archive to upload to store.kde.org: the package with metadata.json at
# the top level, which is what "Get New Plugins" hands to kpackagetool.
dist: build
	mkdir -p dist
	tar -C $(PKG) --sort=name --owner=0 --group=0 --numeric-owner -czf $(DIST) \
		metadata.json LICENSE CREDITS.md contents
	@echo $(DIST)

# Plasma caches wallpaper QML; restart plasmashell to pick up an upgrade:
#   systemctl --user restart plasma-plasmashell
install: build
	kpackagetool6 --type Plasma/Wallpaper --upgrade $(PKG) || kpackagetool6 --type Plasma/Wallpaper --install $(PKG)

uninstall:
	kpackagetool6 --type Plasma/Wallpaper --remove $(ID)
