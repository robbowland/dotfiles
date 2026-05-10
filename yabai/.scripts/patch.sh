#!/bin/sh

set -eu

# Run in case of:
#
# > sudo yabai --load-sa
# > could not spawn remote thread: (os/kern) protection failure
# > yabai: scripting-addition failed to inject payload into Dock.app!
#
# Source: https://github.com/asmvik/yabai/issues/2686#issuecomment-3678216885

patch_caps() {
  file="$1"

  if [ ! -f "$file" ]; then
    printf >&2 "Error: '%s' not found\n" "$file"
    return 1
  fi

  # Get index (I) and offset (O) for caps 0x81
  result="$(otool -f "$file" | awk '/architecture/{i=$2} /capabilities 0x81/{f=1} f&&/offset/{print i, $2; exit}')"

  if [ -z "$result" ]; then
    printf "No target architecture (caps 0x81) found in '%s'.\n" "$file"
    return 0
  fi

  set -- $result
  arch_index="$1"
  offset="$2"

  # Patch Fat (offset+4) and Mach-O (slice+11) -> 0x80.
  printf '\200' | dd of="$file" bs=1 seek=$((8 + arch_index * 20 + 4)) count=1 conv=notrunc 2>/dev/null
  printf '\200' | dd of="$file" bs=1 seek=$((offset + 11)) count=1 conv=notrunc 2>/dev/null

  printf "Patched %s (Arch %s). Resigning...\n" "$file" "$arch_index"
  codesign -f -s - "$file" >/dev/null 2>&1
}

patch_caps "/Library/ScriptingAdditions/yabai.osax/Contents/MacOS/loader"
