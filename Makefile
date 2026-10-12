PKG := package
ID := org.dimap.desktop1984
SHADER := $(PKG)/contents/shaders/pixels.frag

.PHONY: build art preview demo install uninstall

build: $(SHADER).qsb art

$(SHADER).qsb: $(SHADER)
	qsb-qt6 --qt6 -o $@ $<

IMAGES := $(PKG)/contents/images

art:
	python3 tools/gen_art.py
	python3 tools/convert.py tools/sources/kde1.png $(IMAGES)/kde1.png
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

# Plasma caches wallpaper QML; restart plasmashell to pick up an upgrade:
#   systemctl --user restart plasma-plasmashell
install: build
	kpackagetool6 --type Plasma/Wallpaper --upgrade $(PKG) || kpackagetool6 --type Plasma/Wallpaper --install $(PKG)

uninstall:
	kpackagetool6 --type Plasma/Wallpaper --remove $(ID)
