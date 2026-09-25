# macOS build prerequisites

How to set up a Mac (Apple Silicon) to build Knulli images with this fork's `Makefile`.
For the reasons behind these choices, see
[ADR 0001](decisions/0001-arch-aware-docker-build-image.md) and
[ADR 0002](decisions/0002-orbstack-and-case-sensitive-build-volume.md).

**Summary:** OrbStack runs the Docker build container. Build trees live on a case-sensitive
APFS volume, the repo points at it through symlinks, and `knulli.mk` mounts that volume into
the container.

---

## 1. Host requirements

| Item | Recommendation |
|------|----------------|
| Mac | Apple Silicon; the more cores the better (reference host: M1 Ultra, 20 cores, 64 GB) |
| Memory | 32 GB or more; give 16–24 GB to the container runtime |
| Disk | Plan for 200+ GB free per target (sources, downloads, ccache, output, drop caches); a rough estimate |
| macOS | A recent release (reference host: macOS 27) |
| Tools | Xcode Command Line Tools (`xcode-select --install`), [Homebrew](https://brew.sh) |

## 2. Homebrew packages

```bash
brew install orbstack findutils coreutils git
```

- **findutils:** required. On Darwin the Makefile calls `gfind` and stops right away if it's missing.
- **coreutils:** provides `nproc`, which the Makefile uses for `MAKE_JLEVEL`.
- **Don't** add the `gnubin` directories to your `PATH`. The build runs GNU tools inside the
  container, and replacing the BSD tools on the host can break macOS and Homebrew scripts.

## 3. OrbStack (Docker runtime)

1. Launch OrbStack. When it asks what to set up, choose **Docker**, not Kubernetes or Linux.
2. Quit Docker Desktop, if installed, and turn off its launch at login, so it doesn't take over
   the `docker` command.
3. OrbStack → Settings → System: set the memory limit to 16–24 GB and allow all CPUs.

Check it:

```bash
docker context ls        # "orbstack" should be marked current
docker version           # client and server both answer
```

We don't use Apple's `container` CLI. It isn't a drop-in replacement for `docker`, and the
Makefile depends on `docker run`/`build` and their options.

## 4. Case-sensitive build volume

The repo volume is case-insensitive APFS (the macOS default), but Buildroot build trees must be
case-sensitive: the kernel sources contain files that differ only by case. So put the build
trees on their own volume. Adding an APFS volume shares free space with the existing container,
so nothing is repartitioned.

```bash
# Find the APFS container that holds the repo (here: disk11)
diskutil info /Volumes/Shared | grep "APFS Container"

diskutil apfs addVolume disk11 "Case-sensitive APFS" KnulliBuild
mkdir -p /Volumes/KnulliBuild/{output,dl,buildroot-ccache,cores-cache,emulators-cache,armhf-cache}

# Optional: keep Spotlight from indexing millions of build files
sudo mdutil -i off /Volumes/KnulliBuild
```

Check that it's case-sensitive:

```bash
cd /Volumes/KnulliBuild && touch Aa aa && ls Aa aa && rm Aa aa   # both files listed
```

## 5. Repository

```bash
git clone git@github.com:hstriepe/knulli-linux.git knulli-linux-fork
cd knulli-linux-fork
git switch development
git remote add upstream https://github.com/knulli-cfw/knulli-linux.git
git fetch upstream
git submodule update --init --recursive
```

### Point the build directories at the volume

The drop targets assume the default layout under the repo (`<repo>/output`, `<repo>/cores-cache`, …),
so don't relocate them with `OUTPUT_DIR`. Symlink them instead. `.gitignore` already ignores all six.

```bash
for d in output dl buildroot-ccache cores-cache emulators-cache armhf-cache; do
  ln -s /Volumes/KnulliBuild/$d $d
done
```

### `knulli.mk` (git-ignored, local settings)

Create `knulli.mk` in the repo root:

```make
# Mount the build volume at the same path in the container so the symlinks resolve there.
DOCKER_OPTS += -v /Volumes/KnulliBuild:/Volumes/KnulliBuild

# Optional: explicit parallelism (defaults to $(nproc))
MAKE_JLEVEL := 20
```

## 6. Verify

```bash
# 1. The volume stays case-sensitive through OrbStack's file sharing
docker run --rm -v /Volumes/KnulliBuild:/v alpine \
  sh -c 'touch /v/Aa /v/aa && ls /v/Aa /v/aa && rm /v/Aa /v/aa'

# 2. The Makefile sees the target, the paths and the docker options
make vars

# 3. Build image (native linux/arm64; i386/multilib packages are skipped, ADR 0001)
make build-docker-image

# 4. Container user mapping and symlinks resolve inside the container
make h700-shell
#   inside: id; echo $HOME; ls -l /build/output /build/dl; touch /h700/.probe && rm /h700/.probe
```

## 7. First build

```bash
make h700-bootstrap    # sysroot, then cores/emulators/armhf drops, then the image; rerun resumes
# later, after changes:
make h700-build
make h700-pkg PKG=<package>
```

Images end up in `output/h700/images/knulli/images/<device>/`, which is on `/Volumes/KnulliBuild`.
`make h700-webserver` serves them over HTTP.

---

## Troubleshooting

| Symptom | Cause / fix |
|---------|-------------|
| `gfind not found! Please install findutils` | `brew install findutils` |
| `docker not found!` | OrbStack isn't running, or Docker Desktop has taken over the `docker` command. Run `docker context use orbstack` |
| Kernel or package build fails on duplicate, missing or overwritten headers | Build tree is on a case-insensitive volume. Check that `output`, `dl` and the caches are symlinks into `/Volumes/KnulliBuild` |
| Inside the container: `I have no name!`, or permission errors under `$HOME` | The Makefile mounts macOS `/etc/passwd`, which doesn't list UID 501 (macOS keeps users in Directory Services). Try `make h700-shell` and `id`; if tools fail, add a passwd entry through `DOCKER_OPTS` |
| Drop targets can't find `/build/output/<board>/host` | `output` was moved with `OUTPUT_DIR` instead of symlinked. Restore the default and use the symlink |
| A package needs 32-bit x86 host libraries (e.g. `mame2016`) | The arm64 build image doesn't have them. Build that target in an amd64 image: `docker build --platform linux/amd64 …` (runs under Rosetta in OrbStack) |
| Builds are slow | File sharing overhead. Fallback: an OrbStack Linux machine (`orb create ubuntu knulli`) with the repo cloned on its native filesystem |
