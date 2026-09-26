#!/bin/bash
# knulli-startup.sh — check and prepare this Mac for Knulli builds
# (docs/macOS_build_prerequisites.md, ADR 0001/0002)
#
#   bin/knulli-startup.sh           check everything, install/start/create what is missing
#   bin/knulli-startup.sh --check   report only, change nothing
#
# Steps: Apple Silicon + Xcode CLT, Homebrew packages, OrbStack running as the docker
# context, the KnulliBuild image mounted (bin/knulli-image.sh), build dirs and repo
# symlinks, knulli.mk, submodules, and the knulli/knulli-build images (arm64 + amd64).

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
VOLUME="/Volumes/KnulliBuild"
BUILD_DIRS=(output dl buildroot-ccache cores-cache emulators-cache armhf-cache)
BREW_FORMULAE=(findutils coreutils gnu-sed git)
IMAGE_ARM64="knulli/knulli-build:latest"
IMAGE_AMD64="knulli/knulli-build:amd64"

CHECK_ONLY=0
case "${1:-}" in
  --check) CHECK_ONLY=1 ;;
  "") ;;
  *) echo "usage: $0 [--check]" >&2; exit 2 ;;
esac

PROBLEMS=0
info() { echo "==> $*"; }
ok()   { echo "  ok   $*"; }
fix()  { echo "  fix  $*"; }
bad()  { echo "  MISSING $*"; PROBLEMS=$((PROBLEMS + 1)); }
die()  { echo "error: $*" >&2; exit 1; }

# run "$@" unless --check; in check mode count it as a problem
apply() {
  local what="$1"; shift
  if (( CHECK_ONLY )); then
    bad "$what"
    return 1
  fi
  fix "$what"
  "$@"
}

info "Host"
[[ "$(uname -s)" == "Darwin" ]] || die "this script is for macOS hosts"
if [[ "$(uname -m)" == "arm64" ]]; then
  ok "Apple Silicon, macOS $(sw_vers -productVersion)"
else
  echo "  warn not Apple Silicon ($(uname -m)); this setup is tested on arm64 only"
fi
if xcode-select -p >/dev/null 2>&1; then
  ok "Xcode Command Line Tools ($(xcode-select -p))"
else
  bad "Xcode Command Line Tools: run 'xcode-select --install', then rerun this script"
  exit 1
fi

info "Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  bad "Homebrew: install it from https://brew.sh, then rerun this script"
  exit 1
fi
ok "brew $(brew --version | head -n1 | awk '{print $2}')"
for f in "${BREW_FORMULAE[@]}"; do
  if brew list --formula "$f" >/dev/null 2>&1; then
    ok "$f"
  else
    apply "brew install $f" brew install "$f" || true
  fi
done
if [[ -d /Applications/OrbStack.app ]] || brew list --cask orbstack >/dev/null 2>&1; then
  ok "OrbStack installed"
else
  apply "brew install --cask orbstack" brew install --cask orbstack || true
fi

info "OrbStack / docker"
if command -v orb >/dev/null 2>&1; then
  if orb status 2>/dev/null | grep -qi running; then
    ok "OrbStack running"
  elif apply "start OrbStack" orb start; then
    for _ in $(seq 1 60); do docker info >/dev/null 2>&1 && break; sleep 1; done
  fi
else
  bad "orb command not found (launch OrbStack once and choose Docker)"
fi
if command -v docker >/dev/null 2>&1; then
  ctx="$(docker context show 2>/dev/null || true)"
  if [[ "$ctx" == "orbstack" ]]; then
    ok "docker context: orbstack"
  else
    apply "docker context use orbstack (was '${ctx:-none}')" docker context use orbstack >/dev/null || true
  fi
  if docker info >/dev/null 2>&1; then
    ok "docker server $(docker version -f '{{.Server.Version}}' 2>/dev/null), $(docker info -f '{{.NCPU}} CPUs, {{.MemTotal}}' 2>/dev/null | awk '{printf "%s %s %.0f GB", $1, $2, $3/1073741824}')"
  else
    bad "docker server not answering"
  fi
else
  bad "docker command not found"
fi

info "Build volume"
if (( CHECK_ONLY )); then
  status="$("$PROJECT_DIR/bin/knulli-image.sh" status)"
  echo "$status" | sed 's/^/  /'
  if ! echo "$status" | grep -q "^Mounted: $VOLUME ("; then
    bad "KnulliBuild.asif is not mounted at $VOLUME (bin/knulli-image.sh up)"
  fi
else
  "$PROJECT_DIR/bin/knulli-image.sh" up | sed 's/^/  /'
fi

if mount | grep -q " on $VOLUME ("; then
  for d in "${BUILD_DIRS[@]}" container/home logs; do
    if [[ -d "$VOLUME/$d" ]]; then
      ok "$VOLUME/$d"
    else
      apply "mkdir $VOLUME/$d" mkdir -p "$VOLUME/$d" || true
    fi
  done
fi

info "Repo symlinks"
for d in "${BUILD_DIRS[@]}"; do
  link="$PROJECT_DIR/$d"
  if [[ -L "$link" ]]; then
    target="$(readlink "$link")"
    if [[ "$target" == "$VOLUME/$d" ]]; then
      ok "$d -> $target"
    else
      bad "$d -> $target (expected $VOLUME/$d; fix it by hand)"
    fi
  elif [[ -e "$link" ]]; then
    bad "$d is a real directory on the case-insensitive repo volume; move it to $VOLUME/$d and symlink it"
  else
    apply "ln -s $VOLUME/$d $d" ln -s "$VOLUME/$d" "$link" || true
  fi
done

info "knulli.mk"
if [[ -f "$PROJECT_DIR/knulli.mk" ]]; then
  for key in "DOCKER_OPTS += -v $VOLUME" "DOCKER := " "EMULATORS_DROP_PYTHON"; do
    if grep -qF "$key" "$PROJECT_DIR/knulli.mk"; then
      ok "has '$key'"
    else
      bad "knulli.mk lacks '$key' (see docs/macOS_build_prerequisites.md, step 5)"
    fi
  done
else
  write_knulli_mk() {
    cat > "$PROJECT_DIR/knulli.mk" <<EOF
# Local build settings (git-ignored). See docs/macOS_build_prerequisites.md
DOCKER_OPTS += -v $VOLUME:$VOLUME

MAKE_JLEVEL := $(sysctl -n hw.ncpu)

# macOS: give the container user a passwd entry and a writable \$HOME,
# and run *_armhf_libs targets in the amd64 image
DOCKER := \$(PROJECT_DIR)/scripts/macos/docker-wrapper.sh

# macOS: harvest-drop.py execs the drop's Linux readelf/strip, so run it in the container
EMULATORS_DROP_PYTHON = \$(DOCKER) run --rm --init -e HOME \\
	-v \$(PROJECT_DIR):\$(PROJECT_DIR) -v $VOLUME:$VOLUME \\
	-v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro \\
	-u \$(UID):\$(GID) -w \$(PROJECT_DIR) knulli/knulli-build python3
EOF
  }
  apply "create knulli.mk" write_knulli_mk || true
fi

info "Submodules"
uninit="$(git -C "$PROJECT_DIR" submodule status | grep -c '^-' || true)"
if (( uninit == 0 )); then
  ok "all initialized"
else
  apply "git submodule update --init --recursive ($uninit not initialized)" \
    git -C "$PROJECT_DIR" submodule update --init --recursive || true
fi

info "Build images"
if docker info >/dev/null 2>&1; then
  if docker image inspect "$IMAGE_ARM64" >/dev/null 2>&1; then
    ok "$IMAGE_ARM64"
  else
    apply "make build-docker-image" make -C "$PROJECT_DIR" build-docker-image || true
  fi
  if docker image inspect "$IMAGE_AMD64" >/dev/null 2>&1; then
    ok "$IMAGE_AMD64"
  else
    apply "docker build --platform linux/amd64 -t $IMAGE_AMD64" \
      docker build --platform linux/amd64 -t "$IMAGE_AMD64" "$PROJECT_DIR" || true
  fi

  if mount | grep -q " on $VOLUME (" && docker image inspect "$IMAGE_ARM64" >/dev/null 2>&1; then
    if docker run --rm --entrypoint sh -v "$VOLUME:/v" "$IMAGE_ARM64" \
         -c 'p=/v/.case-$$; touch $p-Aa $p-aa && [ "$(ls $p-* | wc -l)" = 2 ]; r=$?; rm -f $p-*; exit $r' 2>/dev/null; then
      ok "$VOLUME is case-sensitive inside the container"
    else
      bad "$VOLUME is not case-sensitive inside the container"
    fi
  fi
else
  bad "docker not available; skipped build images"
fi

echo
if (( PROBLEMS )); then
  echo "$PROBLEMS item(s) need attention."
  (( CHECK_ONLY )) && echo "Rerun without --check to fix what can be fixed automatically."
  exit 1
fi
echo "Ready: make h700-bootstrap (first time) or make h700-build"
