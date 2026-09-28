#!/bin/bash
# Renders a sequence of screens for visual review.
cd "$(dirname "$0")/.."
rm -rf ~/.local/share/godot/app_userdata/*
OUT=${OUT:-/tmp/claude-0/shots}
mkdir -p $OUT
xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --script tools/shot.gd -- $OUT ${W:-1600} ${H:-900} "$@" 2>&1 | grep -E "SCRIPT ERROR|ERROR: |at: res" | grep -v "status < 0\|RID alloc"
