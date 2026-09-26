# ADR 0001: Architecture-aware Docker build image

**Status:** Accepted — 2026-09-25

## Context

Knulli builds run inside the `knulli/knulli-build` Docker image produced from `./Dockerfile`
(`make build-docker-image`). Upstream's Dockerfile assumes an amd64 host: it runs
`dpkg --add-architecture i386` and installs `libc6:i386`, `libncurses6:i386`,
`libstdc++6:i386`, `gcc-multilib` and `g++-multilib`.

This fork is developed on Apple Silicon. There Docker builds a `linux/arm64` image by
default, and Ubuntu arm64 has no i386 foreign architecture and no `gcc-multilib` /
`g++-multilib` packages, so the image fails to build.

## Decision

Make `./Dockerfile` choose packages based on the host architecture, using BuildKit's
`TARGETARCH` build argument:

- `amd64`: add the i386 architecture and install the 32-bit host libs and multilib compilers, as upstream does.
- any other architecture (e.g. `arm64`): skip them; every other package stays the same.

The original amd64-only file is kept as `Dockerfile_x64` for reference and for diffing
against upstream.

## Consequences

- The build image can be built and run natively on Apple Silicon, with no amd64 emulation.
- Packages whose host tools need 32-bit x86 host libraries (the Dockerfile names `mame2016`)
  will not build in an arm64 image. If such a package is enabled for a target, build that target
  in an amd64 image instead (`docker build --platform linux/amd64 …`, emulated on Apple Silicon)
  or on an amd64 host.
- A native arm64 host is not a configuration upstream tests. Host-tool failures that don't happen
  on amd64 should be checked against this ADR first.
- Upstream merges that touch `Dockerfile` need manual reconciliation; compare against `Dockerfile_x64`.

## Amendment — 2026-09-26

The "needs amd64" case happened on the first build, though not through `mame2016`: the
`*_armhf_libs` configs enable `batocera-luajit`, which requires `gcc -m32` on the host. On macOS
these targets now run in `knulli/knulli-build:amd64` automatically, via
`scripts/macos/docker-wrapper.sh` (ADR 0002, Amendment item 4). Every other target stays native
arm64.
