# ADR 0003: SSH and Samba on a non-POSIX share

**Status:** Accepted — 2026-09-26

## Context

`/userdata` (SHARE) can be ext4/btrfs, or a filesystem with no Unix owners, modes or
xattrs: vfat, exFAT, or NTFS. On the H700 4.9 kernel, exFAT is mounted with FUSE `mount.exfat`
(or the kernel driver with `umask=000`), and NTFS with `ntfs-3g`.

- `/etc/dropbear` links to `/userdata/system/.ssh`, and root's home is `/userdata/system`.
  Dropbear checks `authorized_keys`, `.ssh` and the home directory, and refuses keys when any
  of them is group/world-writable. On exFAT every file is `0777`, so key login fails.
  Reproduced on the target's own dropbear 2026.91 over a FUSE exFAT loop mount:
  `No auth methods could be used`. On vfat (default `0755`) key login already worked.
- Samba stores DOS attributes and streams in xattrs by default (`ea support`,
  `store dos attributes`). Those fail on these filesystems, and macOS clients then fall back
  to AppleDouble `._*` files, which the `[share]` section vetoes.

## Decision

1. The SSH service (`/usr/share/knulli/services/ssh`) checks the filesystem type of
   `/userdata/system` (`stat -f -c %T`: `msdos`, `vfat`, `exfat`, `fuse`, `fuseblk`, `ntfs`).
   On those filesystems it copies the host keys and `authorized_keys` into
   `/var/run/dropbear-share` (tmpfs, `0700`/`0600`), and runs dropbear with `-r` for each key
   and `-D` for that directory. Missing host keys are generated there with `dropbearkey` and
   copied back to `/userdata/system/ssh`, so they don't change on every boot. ext4/btrfs keep
   the old behavior (`-R`, keys read in place).
2. The Samba service checks `/userdata` the same way. On those filesystems it starts
   smbd/nmbd with `/var/run/samba/smb.conf`, which includes the selected config and overrides
   `[share]`: no EA/DOS attribute storage, no `map *` attributes, only `.DS_Store` vetoed
   (`delete veto files = yes`).

## Consequences

- The share still holds the persistent copies, so users edit `authorized_keys` as before.
  The running copy is read at service start, so an edit takes effect after SSH is turned
  off and on, or after a reboot.
- Host keys on the share stay world-readable (the filesystem can't do better). Anyone who can
  read the SD card could already read them.
- On these filesystems, Samba doesn't keep DOS hidden/system/archive attributes, and macOS
  metadata ends up in `._*` files on the share.
- Only the services changed; the mount options and `S11share` did not, so ext4/btrfs systems see
  no change.
