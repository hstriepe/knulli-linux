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
