#!/bin/bash
# knulli-image.sh — manage a case-sensitive APFS ASIF image for Knulli builds
#
#   bin/knulli-image.sh            same as "up"
#   bin/knulli-image.sh up         create (if missing), attach, verify case sensitivity
#   bin/knulli-image.sh down       eject the image
#   bin/knulli-image.sh status     show image and mount state
#   bin/knulli-image.sh reformat   WIPE the attached image and reformat as Case-sensitive APFS
#
# Requires macOS 26 (Tahoe) or later for ASIF.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
IMAGE="$PROJECT_DIR/KnulliBuild.asif"
SIZE="512G"
VOLNAME="KnulliBuild"
MOUNT="/Volumes/$VOLNAME"
FS="Case-sensitive APFS"

die()  { echo "error: $*" >&2; exit 1; }
info() { echo "==> $*"; }

check_macos() {
  local major
  major=$(sw_vers -productVersion | cut -d. -f1)
  (( major >= 26 )) || die "ASIF needs macOS 26 or later (this Mac runs $(sw_vers -productVersion))"
}

# Whole-disk devices that diskutil labels "(disk image)"
image_disks() {
  diskutil list | awk '/^\/dev\/disk[0-9]+ \(disk image\)/ {print $1}' | sort
}

is_mounted() { mount | grep -q " on $MOUNT ("; }

# Where this image's volume is mounted (empty if not attached/mounted)
image_mount() {
  hdiutil info | awk -v img="$IMAGE" -F'\t' '
    /^image-path/ { p = $0; sub(/^image-path *: /, "", p); on = (p == img) }
    /^=+$/        { on = 0 }
    on && /^\/dev\// && $3 != "" { print $3; exit }'
}

# $MOUNT is taken by some other volume (e.g. an older KnulliBuild)
check_mount_free() {
  if is_mounted && [[ "$(image_mount)" != "$MOUNT" ]]; then
    die "$MOUNT is another volume, not $IMAGE. Eject it first: diskutil eject '$MOUNT'"
  fi
}

personality() {
  diskutil info "$MOUNT" | awk -F': *' '/File System Personality/ {print $2}'
}

# Attach the image and print the new /dev/diskN it appeared as
attach_image() {
  local before after
  before=$(image_disks)
  diskutil image attach "$IMAGE" >/dev/null
  after=$(image_disks)
  comm -13 <(echo "$before") <(echo "$after") | head -n1
}

# Whole image disk backing the mounted volume
whole_disk_for_mount() {
  local store
  store=$(diskutil info "$MOUNT" | awk -F': *' '/APFS Physical Store/ {print $2}')
  [[ -n "$store" ]] || die "can't find the physical store for $MOUNT"
  diskutil info "$store" | awk -F': *' '/Part of Whole/ {print "/dev/"$2}'
}

create_image() {
  local dir dev
  dir=$(dirname "$IMAGE")
  [[ -d "$dir" ]] || die "directory not found: $dir (is /Volumes/Shared mounted?)"

  info "Creating $SIZE ASIF image at $IMAGE"
  diskutil image create blank --format ASIF --size "$SIZE" --volumeName "$VOLNAME" "$IMAGE"

  info "Attaching"
  dev=$(attach_image)
  [[ -n "$dev" ]] || die "image attached but its device couldn't be identified; run '$0 reformat'"

  info "Reformatting $dev as $FS"
  diskutil eraseDisk "$FS" "$VOLNAME" GPT "$dev"
}

verify() {
  local m
  m=$(image_mount)
  [[ -n "$m" ]] || die "$IMAGE is not mounted"
  [[ "$m" == "$MOUNT" ]] || die "$IMAGE is mounted at '$m', not $MOUNT (another volume named $VOLNAME was mounted first)"
  local p
  p=$(personality)
  if [[ "$p" == "$FS" ]]; then
    info "OK: $MOUNT is $p"
  else
    die "$MOUNT is '$p', not case-sensitive. Run '$0 reformat' to wipe and reformat it."
  fi
}

cmd="${1:-up}"
case "$cmd" in
  up)
    check_macos
    check_mount_free
    if [[ ! -e "$IMAGE" ]]; then
      create_image
    elif [[ -n "$(image_mount)" ]]; then
      info "$MOUNT is already mounted"
    else
      info "Attaching existing image"
      diskutil image attach "$IMAGE" >/dev/null
    fi
    verify
    ;;

  down)
    m=$(image_mount)
    if [[ -n "$m" ]]; then
      info "Ejecting $m"
      diskutil eject "$m"
    else
      info "$IMAGE is not mounted"
    fi
    ;;

  status)
    if [[ -e "$IMAGE" ]]; then
      echo "Image:   $IMAGE ($(du -h "$IMAGE" | cut -f1) on disk, $SIZE max)"
    else
      echo "Image:   not created"
    fi
    m=$(image_mount)
    if [[ -n "$m" ]]; then
      echo "Mounted: $m ($(diskutil info "$m" | awk -F': *' '/File System Personality/ {print $2}'))"
      df -h "$m" | tail -n1
      [[ "$m" == "$MOUNT" ]] || echo "Warning: expected at $MOUNT; another volume named $VOLNAME is mounted there"
    else
      echo "Mounted: no"
    fi
    ;;

  reformat)
    check_macos
    is_mounted || die "attach the image first ('$0 up' will attach it and then report the format)"
    # never erase a volume that isn't this image
    [[ "$(image_mount)" == "$MOUNT" ]] || die "$MOUNT is not $IMAGE; refusing to erase it"
    dev=$(whole_disk_for_mount)
    read -r -p "This ERASES everything on $MOUNT ($dev). Type 'yes' to continue: " ans
    [[ "$ans" == "yes" ]] || die "aborted"
    diskutil eraseDisk "$FS" "$VOLNAME" GPT "$dev"
    verify
    ;;

  *)
    die "usage: $0 [up|down|status|reformat]"
    ;;
esac
