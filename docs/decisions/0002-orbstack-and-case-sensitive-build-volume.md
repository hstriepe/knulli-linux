# ADR 0002: OrbStack runtime and a case-sensitive build volume

**Status:** Accepted — 2026-09-25

## Context

The build host is an Apple M1 Ultra Mac (20 cores, 64 GB, macOS 27). The repo lives on
`/Volumes/Shared`, which is **case-insensitive APFS**.

- The `Makefile` drives every target through the `docker` CLI (`docker build/run/pull/push`,
  with `--init`, `-u UID:GID`, `/etc/passwd` and `/etc/group` mounts, and a set of `-v` mounts).
- Buildroot needs a case-sensitive filesystem for its build trees. The repo sources have no
  case-colliding paths (checked for the repo, `buildroot/` and `batocera/`), but the trees
  unpacked under `output/` do, e.g. the kernel's netfilter `xt_TCPMSS.h` / `xt_tcpmss.h`.
  The libretro checkouts under `cores-cache/` are a similar risk.
- On `development`, the drop targets assume the default layout under Docker: `CORES_DROP_OUTPUT`
  is hard-coded to `/build/output`, and `cores-cache`, `emulators-cache` and `armhf-cache` are
  fixed under `PROJECT_DIR`. So moving `OUTPUT_DIR` through `knulli.mk` would break `%-cores-drop`.

We compared two runtimes: OrbStack, and Apple's `container` CLI (`brew install container`).

## Decision

1. **Use OrbStack** as the Docker runtime. It provides the `docker` CLI, so the Makefile works
   unchanged, and it can run a `linux/amd64` image under Rosetta when a package needs one
   (see ADR 0001). Apple's `container` is not a drop-in for the `docker` CLI: using it would mean
   rewriting `RUN_DOCKER` or giving up the `make <target>-*` workflow.
2. **Keep build trees on a separate case-sensitive APFS volume**, `/Volumes/KnulliBuild`, created
   in the same APFS container (`disk11`) with no repartitioning:
   `diskutil apfs addVolume disk11 "Case-sensitive APFS" KnulliBuild`.
3. **Keep the Makefile's default paths** by making `output`, `dl`, `buildroot-ccache`,
   `cores-cache`, `emulators-cache` and `armhf-cache` in the repo **symlinks** into that volume.
   `.gitignore` already ignores all six.
4. **Mount the volume at the same path inside the container**, so the symlinks resolve there too.
   This goes in the git-ignored `knulli.mk`:
   ```make
   DOCKER_OPTS += -v /Volumes/KnulliBuild:/Volumes/KnulliBuild
   MAKE_JLEVEL := 20
   ```

## Consequences

- `make h700-bootstrap` / `h700-build` run as upstream intends. No Makefile changes, so there is
  nothing to reconcile on upstream merges.
- Build output stays visible in Finder and VS Code at `/Volumes/KnulliBuild`.
- Bind-mounted I/O goes through OrbStack's file sharing. If full builds turn out too slow, the
  fallback is an OrbStack Linux machine (`orb create ubuntu knulli`) with the repo cloned onto its
  native filesystem.
- A fresh clone or another machine needs the volume, the six symlinks and `knulli.mk` recreated.
  Nothing in git records them except this ADR.
- The host also needs `gfind` (`brew install findutils`), which the Makefile requires on Darwin.
  `nproc` is missing on macOS, hence `MAKE_JLEVEL` above.
- Not yet verified here, because OrbStack isn't installed yet:
  - case sensitivity is preserved through OrbStack's file sharing;
  - the `/etc/passwd` mount works for UID 501, which macOS keeps in Directory Services rather
    than in `/etc/passwd`.

  Check both on the first build.
- Spotlight will index the build volume. Consider `sudo mdutil -i off /Volumes/KnulliBuild`.
