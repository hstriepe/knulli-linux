# Architecture Decision Records

Durable decisions for this fork. One file per decision: `NNNN-short-slug.md`, numbered sequentially.
Supersede rather than edit: add a new ADR and mark the old one `Superseded by NNNN`.

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [0001](0001-arch-aware-docker-build-image.md) | Architecture-aware Docker build image | Accepted |
| [0002](0002-orbstack-and-case-sensitive-build-volume.md) | OrbStack runtime and a case-sensitive build volume | Accepted |
| [0003](0003-ssh-and-samba-on-non-posix-share.md) | SSH and Samba on a non-POSIX share | Accepted |

## Template

```markdown
# ADR NNNN: <Title>

**Status:** Proposed | Accepted | Superseded by NNNN — YYYY-MM-DD

## Context

<Problem, forces, constraints.>

## Decision

<What we do.>

## Consequences

<Trade-offs, follow-ups, what becomes easier/harder.>
```
