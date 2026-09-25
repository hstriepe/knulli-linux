# KNULLI Linux (fork) — AI / contributor primer

> Read `AGENTS.md` (if present) before this file. This file takes precedence on any conflict.

For full product documentation, see [README.md](README.md) and the [Knulli wiki](https://knulli.org).

---

## What it is

**Knulli CFW** is a custom firmware for retro-gaming handhelds, forked from
[Batocera](https://github.com/batocera-linux/batocera.linux). It is a Buildroot
`BR2_EXTERNAL` tree that produces bootable SD-card images per SoC family.

- **This fork:** `hstriepe/knulli-linux` (upstream: `knulli-cfw/knulli-linux`, remote `upstream`; dev branch `development`)
- **Fork goal:** build a working image for the **Anbernic DS Plus (H700 variant)**
- **Primary target:** `h700` (`configs/knulli-h700.board`, `board/allwinner/h700/`)
- **Build system:** Buildroot (submodule `buildroot/`, from `knulli-cfw/buildroot`) run inside a Docker build image
- **Distribution:** SD-card images (`output/<target>/images/`)

---

## Repository layout

| Path | Role |
|------|------|
| `configs/knulli-<target>.board` | Build flags per target; `knulli-board.common` is shared |
| `board/<vendor>/<soc>/` | Platform config: kernel configs, patches, fsoverlay, per-device folders (e.g. `board/allwinner/h700/rg35xx-plus/`) |
| `package/` | Knulli packages (emulators, cores, controllers, system, utils…); `.mk` + `Config.in` per package |
| `batocera/` | Batocera submodule (upstream packages Knulli builds on) |
| `buildroot/` | Buildroot submodule — treat as read-only |
| `scripts/` | Image/device helper scripts |
| `Makefile` | Docker-wrapped Buildroot driver (`make vars` lists targets) |
| `Dockerfile` | Build image, arch-aware (amd64 + arm64 hosts) — see ADR 0001 |
| `Dockerfile_x64` | Original amd64-only build image, kept for reference |
| `docs/PROMPT.md` | Human prompts (input only) |
| `docs/CHAT.md` | Plans, actions, results, and debug log (`## LOG`) |
| `docs/decisions/` | Architecture Decision Records (ADRs) |

---

## Architecture

- **Target selection:** each `configs/knulli-*.board` file defines a target; the `Makefile` derives `TARGETS` from those filenames.
- **armhf sub-build:** `h700`, `rk3326`, `rk3566`, `rk3576` also have `*_armhf_libs` boards/packages that build 32-bit libs bundled into the 64-bit image.
- **Per-device support:** device folders under `board/allwinner/h700/` hold device tree, boot config, `genimage.cfg`, partitions and patches. The DS Plus has no folder yet.
- **Packages:** standard Buildroot packages (`<pkg>.mk`, `Config.in`), wired in through `Config.in` / `external.mk` at the repo root.
- **Build container:** the `Makefile` runs Buildroot in `knulli/knulli-build`, mounting the repo at `/build` and `output/<target>` at `/<target>`.

---

## Build

```bash
make vars                       # list targets and effective settings
make build-docker-image         # build knulli/knulli-build from ./Dockerfile
make h700-config                # generate defconfig for the target
make h700-build                 # full image build
make h700-shell                 # shell inside the build container
make h700-pkg PKG=<package>     # rebuild a single package
make h700-kernel                # kernel menuconfig/rebuild
make h700-clean                 # wipe output/h700
```

macOS hosts: `gfind` is required (`brew install findutils`). On Apple Silicon the image is
built for `linux/arm64` and skips i386/multilib packages (ADR 0001). The Makefile mounts
`/etc/passwd` and `/etc/group` into the container, which behaves differently on macOS than
on Linux; check that first if the build fails with permission or user errors.

Useful knobs (env or `knulli.mk`): `PARALLEL_BUILD=1`, `MAKE_JLEVEL=N`, `DL_DIR`, `OUTPUT_DIR`, `CCACHE_DIR`, `DIRECT_BUILD=1` (skip Docker).

---

## Conventions

- Small, task-scoped changes; match existing Buildroot/Makefile/Python style.
- Prefer patches next to the package (`package/.../<pkg>/`) over `board/.../patches`, unless the patch is board-specific.
- Device-specific work for this fork goes under `board/allwinner/h700/` (new device folder for the DS Plus).
- Do not modify `buildroot/` or `batocera/` submodules unless explicitly asked; override from this tree instead.
- User-facing changes: update `README.md` / `knulli-Changelog.md`.
- Policy/architecture changes: add/update an ADR in `docs/decisions/`.
- Do not commit build artifacts (`output/`, `dl/`, `buildroot-ccache/`).

---

## High-risk areas

- [ ] Kernel config and device tree for the DS Plus (H700) — display, input, audio, LEDs
- [ ] Boot chain / `genimage.cfg` / partitions for new device folders
- [ ] armhf libs sub-build (`knulli-h700_armhf_libs`)
- [ ] Image generation scripts (recent upstream changes around rootfs reuse and `firmware.sig`)
- [ ] Controller definitions (`package/controllers`) and ES input mapping
- [ ] Docker host architecture (amd64 vs arm64) — packages needing i386 host libs

---

## Chat workflow

1. User posts working prompt from `docs/PROMPT.md`.
2. Assistant responds with **plan only** (approval gate).
3. After approval, assistant appends plan summary to `## LOG` in `docs/CHAT.md`.
4. Execution summaries, fixes, and amendments are appended there as they occur.
5. On completion, user adds: `--> version (BUILDNUMBER)` using `git rev-list --count HEAD`.

ADRs capture durable decisions; `docs/CHAT.md` captures chronological history; `docs/PROMPT.md` holds human prompts only; this file captures stable contributor guidance.
