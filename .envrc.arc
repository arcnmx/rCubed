#FLAKE_SHELL=dev
FLAKE_ARGS+=(
	--override-input nixpkgs nixpkgs
	--builders ""
)
export DISPLAY=${DISPLAY-:0}

export ARC_STATEDIR=${ARC_STATEDIR-$(direnv_layout_dir)}

PATH_add_bin r3-wine <<'EOF'
#!/usr/bin/env bash
set -eu

if [[ ! -d bin/release/R3 ]]; then
	make package TSA=none
fi

R3MODE=release
if [[ $# -gt 0 ]]; then
	R3MODE=$1
	shift
fi
if [[ $R3MODE = debug ]]; then
	make $R3MODE
	R3MODE=develop
else
	make $R3MODE
fi

mkdir -p $ARC_STATEDIR/wine/$R3MODE
ln -sf ~/.cache/r3air/Adobe\ AIR ~/.cache/r3air/R3.exe $ARC_STATEDIR/wine/$R3MODE/
ln -rsf $FLAKE_ROOT/bin/release/R3/{changelog.txt,mimetype,META-INF,data} $ARC_STATEDIR/wine/$R3MODE/

ln -rsf $FLAKE_ROOT/bin/$R3MODE/R3Air.swf $ARC_STATEDIR/wine/$R3MODE/

bitw show -f password ffr | xsel -b
exec nix run nixpkgs#wine64 -- $ARC_STATEDIR/wine/$R3MODE/R3.exe "$@"
EOF

PATH_add_bin r3-ruffle <<'EOF'
#!/usr/bin/env bash
set -eu

if [[ ! -d bin/release/R3 ]]; then
	make package TSA=none
fi

R3MODE=release
if [[ $# -gt 0 ]]; then
	R3MODE=$1
	shift
fi
if [[ $R3MODE = debug ]]; then
	make $R3MODE
	R3MODE=develop
else
	make $R3MODE
fi

bitw show -f password ffr | xsel -b
exec nix shell nixpkgs#gnome.zenity nixpkgs#ruffle -c ruffle_desktop bin/$R3MODE/R3Air.swf \
	--player-runtime air \
	-Pruffle=1 \
	"$@"
EOF

PATH_add_bin r3-tail <<'EOF'
#!/usr/bin/env bash
set -eu

exec tail -f "$XDG_DOCUMENTS_DIR/logs-air.txt"
EOF

PATH_add_bin deploy <<'EOF'
#!/usr/bin/env bash
set -eu

make release
scp bin/release/R3Air.swf hakurei:/srv/ffr/R3Air.swf
EOF
