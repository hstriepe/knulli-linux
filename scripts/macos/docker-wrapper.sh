#!/bin/bash
# docker wrapper for macOS build hosts (see docs/macOS_build_prerequisites.md, ADR 0002).
#
# The Makefile's RUN_DOCKER mounts the host /etc/passwd and /etc/group so the
# container knows the building user.  macOS keeps users in Directory Services,
# not /etc/passwd, so inside the container the UID has no name and $HOME is a
# root-owned mount point.  For "docker run" this wrapper:
#   - swaps those two mounts for generated files: the image's own passwd/group
#     plus an entry for the current user;
#   - mounts a writable home directory at $HOME.
# Every other docker command passes through unchanged.
#
# Select it in knulli.mk:  DOCKER := $(PROJECT_DIR)/scripts/macos/docker-wrapper.sh

set -euo pipefail

REAL_DOCKER=${REAL_DOCKER:-docker}
STATE_DIR=${KNULLI_DOCKER_STATE_DIR:-/Volumes/KnulliBuild/container}

if [[ "${1:-}" != "run" ]]; then
    exec "$REAL_DOCKER" "$@"
fi

# Account files are taken from the build image (parsing the image name out of
# the run arguments would be fragile).
IMAGE=${KNULLI_DOCKER_IMAGE:-knulli/knulli-build}

uid=$(id -u); gid=$(id -g); user=$(id -un)
mkdir -p "$STATE_DIR/home"
passwd="$STATE_DIR/passwd"; group="$STATE_DIR/group"

if [[ ! -s "$passwd" || ! -s "$group" ]]; then
    "$REAL_DOCKER" run --rm --entrypoint cat "$IMAGE" /etc/passwd > "$passwd.tmp"
    "$REAL_DOCKER" run --rm --entrypoint cat "$IMAGE" /etc/group  > "$group.tmp"
    grep -q "^[^:]*:[^:]*:${uid}:" "$passwd.tmp" || \
        echo "${user}:x:${uid}:${gid}:${user}:${HOME}:/bin/bash" >> "$passwd.tmp"
    grep -q "^[^:]*:[^:]*:${gid}:" "$group.tmp" || \
        echo "${user}:x:${gid}:" >> "$group.tmp"
    mv "$passwd.tmp" "$passwd"; mv "$group.tmp" "$group"
fi

# Targets whose Buildroot config needs a 32-bit x86 host compiler (gcc -m32):
# the *_armhf_libs configs, via batocera-luajit (BR2_HOSTARCH_NEEDS_IA32_COMPILER).
# An aarch64 gcc has no -m32, so these run in the amd64 image (ADR 0001),
# emulated by OrbStack.  Matched on the "-v <out>/<target>:/<target>" mount.
AMD64_TARGETS_RE=${KNULLI_AMD64_TARGETS_RE:-_armhf_libs$}
use_amd64=
for a in "$@"; do
    if [[ "$a" == *:/* && "${a##*:/}" =~ $AMD64_TARGETS_RE ]]; then
        use_amd64=1
    fi
done

args=()
for a in "$@"; do
    case "$a" in
        /etc/passwd:/etc/passwd:ro) args+=("$passwd:/etc/passwd:ro") ;;
        /etc/group:/etc/group:ro)   args+=("$group:/etc/group:ro") ;;
        "$IMAGE")                   args+=("${use_amd64:+--platform=linux/amd64}" "$IMAGE${use_amd64:+:amd64}") ;;
        *)                          args+=("$a") ;;
    esac
done
# drop the empty placeholder left when not switching platform
clean=()
for a in "${args[@]}"; do [[ -n "$a" ]] && clean+=("$a"); done

# insert the home mount right after "run"
exec "$REAL_DOCKER" run -v "$STATE_DIR/home:$HOME" "${clean[@]:1}"
