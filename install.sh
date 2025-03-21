#!/usr/bin/env bash

# Install scripts and completions into user home

set -euo pipefail

cd "$(dirname "$0")"

bin=~/.local/bin/
mkdir -p "$bin"
cp bin/* "$bin"

fish_completions="${XDG_DATA_HOME-$HOME/.local/share}"/fish/vendor_completions.d/
mkdir -p "$fish_completions"
cp completions/*.fish "$fish_completions"
