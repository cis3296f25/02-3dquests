#!/bin/sh
printf '\033c\033]0;%s\a' 3D Quests
base_path="$(dirname "$(realpath "$0")")"
"$base_path/3DQuestsServer.x86_64" "$@"
