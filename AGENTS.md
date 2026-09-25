# Agents

This file lists Claude agents and specialized tools available for Knulli Linux (fork) work.

## Active agents

| Agent | When to use | Notes |
|-------|------------|-------|
| **Explore** | Locating a package `.mk`/`Config.in`, tracing a `BR2_PACKAGE_*` flag through `configs/`, finding device folders under `board/` | Read-only; fast. Say whether to include the `batocera/` and `buildroot/` submodules — they are large. |
| **Plan** | Designing device bring-up (DS Plus on H700), kernel/DTS changes, package additions | Use before touching boot chain, kernel config or armhf libs. |
| **General-purpose** | Multi-step research, build-failure debugging, end-to-end implementation | Default for most tasks; full tool access. |

## Skills

| Skill | When to use |
|-------|------------|
| **`/code-review`** | Review pending changes for correctness, simplification, efficiency. |
| **`/engineering:debug`** | Structured debugging of Buildroot/kernel build failures. |
| **`/engineering:architecture`** | Draft or review an ADR in `docs/decisions/`. |
| **`/init`** | Initialize or refresh CLAUDE.md documentation. |

## External references

- **Build:** the `Makefile` is authoritative (`make vars`); Buildroot manual for package/infrastructure semantics.
- **Knulli wiki:** https://knulli.org
- **Compile guide:** https://wiki.batocera.org/compile_knulli.linux
- **Upstream:** https://github.com/knulli-cfw/knulli-linux — remote `upstream`; branches `knulli-main`, `development` (this fork: `hstriepe/knulli-linux`). The old `knulli-cfw/distribution` repo is archived (pre-Gladiator II) and unrelated in history.
- **Batocera:** https://github.com/batocera-linux/batocera.linux (submodule `batocera/`)
- **Community:** Knulli Discord (see README) for device-specific questions.
