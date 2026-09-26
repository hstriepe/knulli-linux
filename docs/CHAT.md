# KNULLI-LINUX (fork) — Build and Release

## TODO

- [x] Finish the `h700-bugfix-1` rebuild; check the exit code and that the image contains `knulli-diag-net`, the new `services/ssh` and `services/samba`, and `modprobe.d/8821cs.conf`.
- [ ] On-device test with an exFAT SHARE: SSH key login, password login, host keys unchanged after a reboot.
- [ ] On-device test: Samba from macOS Finder (copy, rename, delete folders) on exFAT and on ext4.
- [ ] On-device test: WPA2 WiFi stays connected (idle, after suspend/resume); check `rtw_power_mgnt`/`rtw_ips_mode` in `/sys/module/8821cs/parameters`.
- [ ] Run `knulli-diag-net` on the device and review the report (NTFS/FAT32 SHARE too).
- [ ] ScreenScraper: get a developer key, then wire it into the build (`keys.txt`) and debug scraping on ext4.
- [ ] Commit the bug fixes (without the regenerated ES `locales/*.po`/`.pot`) and push `development`.
- [ ] DS Plus (H700) bring-up: new device folder under `board/allwinner/h700/` (device tree, boot config, `genimage.cfg`, partitions).

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

### 2026-09-26 — Bug fixes: SSH/Samba off ext4, WiFi (WPA2), ScreenScraper

**Plan (approved):** SHARE on vfat/exFAT/NTFS (SD1 reformatted or SD2) breaks SSH and Samba; WPA2 WiFi drops on H700; ScreenScraper fails on ext4 (stock Knulli).
1. `knulli-diag-net`: on-device diagnostics written to `/userdata/system/logs/` (readable from a PC when SSH is broken).
2. WiFi: `modprobe.d/8821cs.conf` (power save off; driver v5.5.1 had no options) and connman `BackgroundScanning=false` for H700. WPA2-only, so no PMF/SAE change.
3. SSH: exFAT/NTFS are FUSE on the 4.9 kernel (no hard links, fsync, or POSIX modes). Keep live host keys and `authorized_keys` on a POSIX path, synced to/from `/userdata/system` with correct modes.
4. Samba: detect the `/userdata` fs type at start; on non-POSIX filesystems disable xattr-based DOS attributes/streams.
5. ScreenScraper: parked until a dev key is available (not compiled into this build); diagnostics capture clock/scraper state.
6. Incremental `make h700-build`, ADR for the SSH key location, README.

**Execution:**
- Clarified: no ScreenScraper dev key yet, so step 5 stays parked.
- WiFi (step 2): `board/allwinner/h700/fsoverlay/etc/modprobe.d/8821cs.conf` (`rtw_power_mgnt=0 rtw_ips_mode=0`) and `BackgroundScanning=false` in the h700 `connman/main.conf`.
- `knulli-diag-net` (step 1): new script in `knulli-scripts` that writes `/userdata/system/logs/knulli-diag-net-<date>.log` (fs types and modes, dropbear/samba state, connman/iw/8821cs params, dmesg, scraper settings and clock).
- SSH (step 3): the cause is dropbear's permission check. On exFAT (FUSE, `0777`), `authorized_keys`, `.ssh` and root's home `/userdata/system` are all world-writable. dropbear 2026.91 no longer uses `link()` for key generation, so host keys work. Fix in `services/ssh`: on msdos/vfat/exfat/fuse/fuseblk/ntfs, copy the host keys and `authorized_keys` to `/var/run/dropbear-share` (0700/0600) and run with `-r … -D`; generated keys are copied back to `/userdata/system/ssh`. Verified in a privileged arm64 container with the target's dropbear/dbclient: **exFAT old = "No auth methods could be used", new = login OK**; vfat worked with both.
- Samba (step 4): `services/samba` writes `/var/run/samba/smb.conf` (includes the chosen config, `[share]` without EA/DOS attributes, only `.DS_Store` vetoed so macOS `._*` files are allowed). Checked with the target `testparm` for both `smb.conf` and `smb-secure.conf`: the overrides merge into `[share]`.
- ADR 0003, README "Fixes in this fork".
- Build: `make h700-pkg PKG=knulli-scripts-reinstall && make h700-build` (log `h700-bugfix-1.log`).
- Build `h700-bugfix-1`: **exit=0** (Sat 2026-09-26 12:47). All 10 device images rebuilt; the target contains `knulli-diag-net`, the new ssh/samba services, `modprobe.d/8821cs.conf` and `BackgroundScanning=false`. Pending: on-device tests (see TODO).

### 2026-09-26 — Build volume as an ASIF image, startup script

- `KnulliBuild.asif` (repo root, git-ignored via `*.asif`) replaces the `disk11s2` APFS volume on the `Shared` AppleRAID stripe. Single case-sensitive APFS volume, no extra partitions needed; the file sits on the same stripe.
- `bin/knulli-image.sh` (up/down/status/reformat): repo-relative image path, finds the image's real mount point via `hdiutil info`, and refuses to act on another volume mounted at `/Volumes/KnulliBuild` (`reformat` would otherwise have targeted the RAID disk). Default size 512G.
- `bin/knulli-startup.sh` (`--check` = report only): Xcode CLT, Homebrew formulae + OrbStack cask, OrbStack running with the docker context, image mounted, build dirs and repo symlinks, `knulli.mk`, submodules, arm64/amd64 build images, case-sensitivity inside the container.
- Measured space: ~186 GiB steady state for h700 (`output/h700` 92, `emulators-drop` 31, `dl` 24, `cores-cache` 19, armhf 15, ccache 4); another target adds ~100 GiB.
- Open: finish the copy, `diskutil image resize --size 512G`, eject the old volume, `bin/knulli-startup.sh`; then update ADR 0002 and `docs/macOS_build_prerequisites.md`.

### 2026-09-26 — RG DS Plus: target and stock firmware analysis

**Finding:** the RG DS Plus is **RK3568**, not H700 (Anbernic spec page). It is a revised RG-DS, so it belongs on the universal `rk3566` image next to `rg-ds`, not under `board/allwinner/h700/`.

**Plan (proposed):** 0) analyse stock firmware; 1) `rk3566-anbernic-rg-ds-plus.dts` in `linux_bsp_patches/0001-knulli-rk3566.patch` + `BR2_LINUX_KERNEL_INTREE_DTS_NAME`; 2) `rcS` model match `"Anbernic RG DS Plus"*` → `rg-ds-plus` **before** the `"Anbernic RG DS"*` glob; 3) add `rg-ds-plus` wherever `rg-ds` is handled (capabilities, audio amp, power LED, wifi, dual-screen DraStic); 4) controller mapping; 5) `make rk3566-bootstrap`; 6) docs/ADR (fork target is rk3566, not h700).

**Step 0 — stock image** `RG-DS-PLUS-EN16GB-20260915.IMG` (work files in `/Volumes/KnulliBuild/anbernic/ds-plus/{parts,x}`):
- GPT, Rockchip Linux SDK layout: uboot, misc, boot (FIT: fdt + kernel + resource), recovery, backup, rootfs 5G, ports, vendor, oem, userdata, ROMS (FAT).
- Kernel **6.1.141** (same series as Knulli's `linux-6.1.y-rockchip`). The FIT config is signed `sha256,rsa2048:dev` (the SDK test key).
- DT model is the generic `"Rockchip RK3568 DEEP LP3 V10 Board"`. We set our own model string.
- Compared with the stock RG-DS DTB (`board/rockchip/rk3566/rg-ds/rk3566-anbernic-rg-ds.dtb`):

| Area | RG-DS | RG DS Plus |
|------|-------|-----------|
| Panels (DSI0 top, DSI1 bottom; same VOP routing) | 640×480, 4 lanes, `aoly,sl008pa21y1285-b00`, flags 0x803 | **1024×768, 2 lanes**, 62.8 MHz, flags 0xe03, new init sequences (the two panels differ, 341/346 bytes), `power-supply` regulator, no `enable1-gpios` |
| Backlight | 2 PWM, power via `gpio-leds` gpio4 PA4/PA3 | 2 PWM, same pins as `enable-gpios` on the backlight |
| Touch | gt9xx on i2c4 (top) and i2c5 (bottom) | **bottom only**: gt9xx i2c5@0x14, 1024×768, reset GPIO0_A6, int GPIO0_C6 |
| Audio | rk817 codec + external amp (spk-ctl gpio4 PC3), aw87391 | rk817 (no spk-ctl) + **2× Awinic AW883xx smart PA** i2c3@0x34/0x35 on I2S1 (reset gpio4 PA7/PB2, irq gpio4 PB0/PB3), firmware `/lib/firmware/aw883xx_acf.bin` (144,920 B). aw87391 disabled. Driver built into the stock kernel (out-of-tree Awinic). |
| Buttons, D-pad, L3/R3, Menu, Vol, amux (gpio3 PC1–PC3, saradc ch3) | singleadc-joypad | `gpio-keys-polled` with vendor key codes, **same pins**. Knulli's `singleadc-joypad` node should carry over. |
| Lid | hall gpio0 PC3 | same pin, read by vendor `anbernic,misc` |
| Rumble | `rk-vibrator-gpio` | PWM motor (`moto.sh`: pwmchip0/pwm2, 50 Hz, 60 %) |
| IMU | icm accel/gyro on | disabled |
| WiFi/BT | RTL8821CS (DT says ap6330), host-wake gpio4 PA1 | same (`RTL8821CS.ko`, `rtl8821c_fw`, `rtlbt/`) |
| Battery | cw2015 + rk817, 4.35 V | new cw2015 profile, 4247 mAh, **4.4 V** charge, new OCV table |
| PMIC | DCDC1/2 min 0.9/0.825 V | min 0.5 V, init 0.9 V; DCDC1 off in suspend |

- Stock userspace: Weston; dual-screen DraStic via `vendor/deep/drastic64/launch.sh` + `ndsCtrl.dge`; second-screen app `vendor/subscreen/`; touch gated via `/sys/class/anbernic_misc/tpctrl`.

**Open items:**
- AW883xx driver: **present** in `knulli-cfw/linux-6.1.y-rockchip` (`sound/soc/codecs/aw883xx/`) and already `=y` in `package/kernels/kernel-rg-ds/linux-rk3566-defconfig.config`. The universal image's `board/rockchip/rk3566/linux-bsp-defconfig.config` has it off: set `CONFIG_SND_SOC_AW883XX=y` and ship `aw883xx_acf.bin` in `/lib/firmware`.
- Panel driver: confirm `simple-panel-dsi` in the Knulli kernel takes the new init sequence and flags.
- Boot chain (rk3566 is a hybrid): `idbloader.img` is a **prebuilt blob** (DDR V1.13, 2022), U-Boot is built from `knulli-cfw/rk356x-uboot` (`rk3566-generic`), and `resource.img` is prebuilt with 7 DTBs picked by **SARADC hardware ID** (RG-DS = `saradc_ch1=525, ch0=1023`).
  - DDR: the stock DS Plus loader is **v1.25** (2025-12). If V1.13 can't initialise its RAM, fall back to the extracted stock `idbloader` (sector 64), H700-style. That affects every rk3566 device, or needs a DS-Plus-only image.
  - Hardware ID: the stock image has a single DTB, so the DS Plus ADC ID is unknown. Read it on the device (`/sys/bus/iio/devices/iio:device0/in_voltage{0,1}_raw` under stock Linux). If it matches the RG-DS, U-Boot picks the RG-DS DTB (640×480 panels → blank screens), and another selector is needed.
  - Secure boot: the stock FIT is signed with the SDK `dev` key. The RG-DS boots Knulli's U-Boot, so verification is probably not enforced.
