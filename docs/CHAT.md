# KNULLI-LINUX (fork) — Build and Release

## LOG

### 2026-09-25 — Initialize agentic work environment

**Prompt:** Initialize CLAUDE, AGENTS, DECISIONS carried over from another project (OpenEmu).

**Plan (approved):**
1. Rewrite `CLAUDE.md` for Knulli: fork goal (Anbernic DS Plus, H700), repo layout, Makefile/Docker build flow, conventions, high-risk areas; keep chat workflow.
2. Rewrite `AGENTS.md`: Knulli-oriented agent usage, skills, external references (wiki, upstream, Batocera).
3. Replace OpenEmu ADRs with `0001-arch-aware-docker-build-image.md` (records the uncommitted Dockerfile change) and add `docs/decisions/README.md` (index + template).
4. Fix `docs/CHAT.md` heading, add `## LOG`.
5. No changes to Dockerfile, build or package files; no commit. `Dockerfile_x64` kept; `.gitignore` untouched.

**Execution:**
- Done: steps 1, 2, 4, and the new ADR 0001 + README from step 3.
- Blocked: deleting OpenEmu ADRs `0001-developer-id-hardened-runtime.md`, `0002-block-intel-core-downloads-on-arm64.md`, `0003-bundle-cores-in-the-app.md`, `0004-revert-core-bundling.md` was denied by the permission classifier. They remain in `docs/decisions/` for the user to remove, and they share the `0001` prefix with the new ADR until then.

### 2026-09-25 — Add upstream remote

- Added remote `upstream`. First pointed at `knulli-cfw/distribution`, but that repo is archived (README: used up to Gladiator II), and its `knulli-dev` (last commit 2025-05-12) shares no history with this fork.
- Repointed `upstream` to `https://github.com/knulli-cfw/knulli-linux` and fetched with prune. Branches: `upstream/knulli-main` (identical to local `knulli-main`, 0/0) and `upstream/development` (local `knulli-main` is 7 ahead, 30 behind). Tag `20260511` fetched.
- Fixed the upstream references in `CLAUDE.md` and `AGENTS.md`.

### 2026-09-25 — Switch to development, merge knulli-main

- Stashed the uncommitted arm64 `Dockerfile` change, created local `development` tracking `upstream/development`, and merged `knulli-main` into it (merge commit `83893ab`, local only, not pushed).
- Conflicts: `board/scripts/post-image-script.sh` (kept both: cores.squashfs + fast H700 multi-image), `package/gpu/mali-libs/mali-libs.mk` (took development's version; main's is a subset), `es_input.cfg` (took knulli-main's Loong Gamepad entry, kept development's other new controllers). `rg34xx-sp/partitions/boot.img` was identical on both sides, so no conflict.
- Submodules updated to development's pins (`buildroot` → origin/development `173e002`, `batocera` → `30b9d48`, plus nested `batocera/buildroot`).
- Reapplied the Dockerfile stash cleanly; it sits next to development's added `bsdextrautils`.
- Note: development's `.gitignore` ignores `/docs`, so these docs are untracked-and-ignored on this branch.

### 2026-09-25 — Track workspace files, push development

- `.gitignore`: dropped upstream's `/docs` ignore (docs/ now tracked); whitelisted `knulli-linux.code-workspace`. `.vscode/` (runtime state) and `.DS_Store` stay ignored.
- Committed `CLAUDE.md`, `AGENTS.md`, `docs/`, `Dockerfile` (arm64-aware), `Dockerfile_x64`, `!git/KNULLI Wiki.webloc`, `knulli-linux.code-workspace`.
- Pushed `development` to `origin` (`hstriepe/knulli-linux`) and set it as the tracking branch; `upstream/development` remains the source to merge from.

### 2026-09-25 — Docker runtime and build volume (ADR 0002)

- Recommendation accepted: OrbStack (drop-in `docker` CLI for the Makefile) over Apple `container`.
- Found: `/Volumes/Shared` is case-insensitive APFS; Buildroot output needs case-sensitive.
- Created APFS volume `KnulliBuild` (Case-sensitive, container `disk11`, `disk11s2`) at `/Volumes/KnulliBuild`, verified case sensitivity.
- On `development` the drop targets hard-code `<repo>/output` and the `*-cache` dirs under Docker, so instead of relocating `OUTPUT_DIR`, the repo's `output`, `dl`, `buildroot-ccache`, `cores-cache`, `emulators-cache`, `armhf-cache` are symlinks into the volume; `knulli.mk` (ignored) adds `DOCKER_OPTS += -v /Volumes/KnulliBuild:/Volumes/KnulliBuild` and `MAKE_JLEVEL := 20`.
- Added ADR 0002; updated the build section of `CLAUDE.md` (drop flow, `h700-bootstrap`, host setup).
- Open: install OrbStack + `findutils`; verify case sensitivity through OrbStack's file sharing and the `/etc/passwd` user mapping on the first build.

### 2026-09-25 — macOS build prerequisites doc

- OrbStack set up with Docker (not Kubernetes/Linux); `findutils` + `coreutils` installed, no `gnubin` on PATH (the Makefile uses `gfind`; `nproc` is unprefixed).
- Added `docs/macOS_build_prerequisites.md` (host requirements, Homebrew, OrbStack, case-sensitive volume, symlinks, `knulli.mk`, verify steps, first build, troubleshooting); linked from `CLAUDE.md`.
- Committed ADR 0002, the doc updates and PROMPT.md; pushed `development` to origin.

### 2026-09-25 — Initial build (h700)

**Plan:** verify the OrbStack environment, build the Docker image, check the container's user mapping, run `make h700-bootstrap BATCH_MODE=1`, and debug until it completes. Logs go to `/Volumes/KnulliBuild/logs/`.

- OrbStack Docker 29.4.0 arm64, 20 CPUs, 16 GB. The volume is still case-sensitive through OrbStack's file sharing (`Aa`/`aa` test).
- `make build-docker-image`: OK (native arm64, ADR 0001).
- Issue: inside the container UID 501 had no passwd entry (`whoami`/`getpwuid` failed) and `$HOME` was a root-owned mount point. Fix: `scripts/macos/docker-wrapper.sh`, selected via `DOCKER :=` in `knulli.mk`. For `docker run` it swaps the passwd/group mounts for generated files (the image's own plus the user) and mounts a writable home from `/Volumes/KnulliBuild/container/home`. Verified: user name resolves, `$HOME` and ccache are writable.
- Started `make h700-bootstrap` (log: `h700-bootstrap-1.log`).
- Sysroot stage: OK. Harmless noise seen and filtered out of the monitor: `(ignored)` make errors, Boost `No best alternative` (histogram), libopenh264 `not a git repository`, rtmpdump git fetch failing and falling back to sources.buildroot.net, Samba pidl `.idl` errors, missing `keys.txt` (optional scraper API keys).
- **cores-drop: `mame` failed to link** (`relocation truncated to fit: R_AARCH64_CALL26`, 43052 drivers). Root cause: for `platform=unix`, MAME's `Makefile.libretro` never forwards `OVERRIDE_CC`/`OVERRIDE_CXX` to genie, so the core was built with the container's native `g++` (on an x86 host this would give an x86 core) and without the profile wrapper flags (`-ffunction-sections`, etc.). Fix, same approach as `same_cdi`: `overlay/patches/_common/mame/0001-plumb-cross-compiler-into-genie.patch` (opt-in `CROSS_BUILD` passes CC/CXX, PLATFORM, and ARCHITECTURE="") and `cores.args`: `mame arm64 LIBRETRO_CPU=arm64 PTR64=1 CROSS_BUILD=1`. To verify with `make h700-cores-drop` after the bootstrap run (the drop tolerates per-core failures, so the run continues).
- Cores drop result: PARTIAL, 129 cores; missing `mame` (fix above) and `hatari`: upstream `libretro/hatari` renamed `master` to `main` (`fatal: Remote branch master not found`). Fixed `coresets/tier3.coreset` to `main`.
- **emulators-drop failed** (bootstrap exit 2). h700 consumes the emulators drop built on the reference board **rk3576** (a second Buildroot build). Two macOS-host issues in the Makefile:
  1. `%-config` runs `sed -i '$(DEFCONFIG_SED)'` on the host, and BSD sed fails (`invalid command code S`). Fix: `SED ?= gsed` on Darwin, mirroring the existing `FIND ?= gfind`, plus `brew install gnu-sed`.
  2. `harvest-drop.py` runs with the host `python3` and execs the drop's Linux `readelf`/`strip`, which can't run on macOS. Fix: new hook `EMULATORS_DROP_PYTHON ?= python3`; `knulli.mk` sets it to run `python3` in the build container, with the repo and the build volume mounted at their host paths. Probe OK (py 3.12, user resolves, paths visible).
- Resumed: `make h700-bootstrap` (log `h700-bootstrap-2.log`). Every step is a no-op when already satisfied; the cores drop retries mame and hatari.
- Run 2: `hatari` now clones `main`, but upstream dropped `Makefile.libretro` (`No rule to make target`); the core is now the CMake target `hatari_libretro` behind `ENABLE_LIBRETRO`. Switched `tier3.coreset` to `CMAKE Makefile build` and added `hatari any -DENABLE_LIBRETRO=ON -DENABLE_HATARI=OFF -DENABLE_TOOLS=OFF` to `cores.args`. Hand test in the container with the aarch64-v8a toolchain file: `hatari_libretro.so` is an aarch64 ELF. Run 2 already passed hatari, so it will be picked up on the next cores-drop.
- Run 2 cores drop: **mame verified**. The patch applied, it built with `aarch64-v8a-g++` (host `gcc` only for genie's build tools, as CROSS_BUILD intends), and it linked without the CALL26 overflow. Drop is now 130 cores, only `hatari` missing (fix already in place for the next cores-drop).
- Run 2 emulators drop (rk3576): **OK**. The gsed + container-python fixes worked; harvested 53 packages. Warnings only: `libfreeimage openbor-common python-batocera-common sdl3-ttf` enabled but not in `emulators.set` (an upstream housekeeping note).
- **armhf-drop failed**: `h700_armhf_libs` enables `batocera-luajit`, which for a 32-bit target selects `BR2_HOSTARCH_NEEDS_IA32_COMPILER` (LuaJIT's host `buildvm` must be 32-bit, built with `gcc -m32`). aarch64 gcc has no `-m32`; this is the case ADR 0001 anticipated. OrbStack emulates linux/amd64, linux/386 and linux/arm/v7 (tested). Fix: built `knulli/knulli-build:amd64` (`docker build --platform linux/amd64`; the Dockerfile installs multilib there); `docker-wrapper.sh` now runs any target whose output mount matches `_armhf_libs$` in the amd64 image. Verified: armhf-libs shell is x86_64 with a working `gcc -m32`; h700 stays aarch64. Removed the arm64-built `output/h700_armhf_libs/build/buildroot-config` so kconfig is rebuilt.
- Run 3: `make h700-bootstrap` (log `h700-bootstrap-3.log`).
- Run 3: cores drop **complete, 131 cores** (hatari verified); emulators drop reused; armhf libs built in the amd64 image (Rosetta) and harvested; `h700-build` OK. **exit=0** (Sat 2026-09-26 01:04). **10 images** in `output/h700/images/knulli/images/<device>/` (rg-cubexx, rg28xx, rg34xx, rg34xx-sp, rg35xx-h, rg35xx-plus, rg35xx-pro, rg35xx-sp, rg40xx-h, rg40xx-v), each ~2.2 GB `.img.gz` + `_boot.tar.gz` + md5/sha256; 42 GB total. Build time ~14 h over three runs (4h20, 2h30, 7h00).
- Side effect: the build regenerates `knulli-es-system` `locales/*.po`/`.pot` (30 files, +31k lines). Left uncommitted.
- Docs: amended ADR 0001 and 0002 with the first-build findings; updated `docs/macOS_build_prerequisites.md` (gnu-sed, amd64 image, full `knulli.mk`, wrapper, timings, troubleshooting) and the CLAUDE.md host setup.
- Note: no DS Plus device folder exists yet; these are the stock H700 device images. The DS Plus bring-up is the next step.
