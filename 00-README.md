# QA proofs: kairos-io/kairos#4462 (fix a DiskFSType panic and its fork per attempt)

## Environment

| item | value |
| --- | --- |
| PR head | `3b0005495` (base `5b30a02bc`, GitHub reports MERGEABLE) |
| ISO | `make iso` from the PR worktree: `kairos-hadron-v0.5.1-standard-amd64-generic-v4.3.0-rc3-5-g3b0005495-k3sv1.36.4+k3s1.iso` |
| host | Ubuntu, Linux 6.8.0-139-generic, qemu-system-x86_64 + KVM, docker 29.6.2 |
| scenario | live ISO, direct kernel boot, `kairos.ram kairos.ram.create_partitions rd.immucore.debug` |

## Why a blkid shim

`DiskFSType`'s BusyBox branch is unreachable on the hadron base image, which
ships util-linux blkid. To reach it on a real boot, `/usr/bin/blkid` in the
initramfs is a shim (`/usr/bin` comes before `/usr/sbin` on the PATH
`CommandWithPath` builds, and the real binary lives at `/usr/sbin/blkid`).
The shim answers BusyBox-style for exactly the two argument shapes
`DiskFSType` uses and `exec`s the real blkid for everything else, so the rest
of the initramfs is unaffected. Every invocation is logged to `/dev/kmsg`,
which is how the fork counts below were measured.

Two shims: `blkid-shim` prints the tagless `<dev>:` line BusyBox prints for a
device it found no tags on (the panic input), `blkid-shim-benign` prints a
real tag list (so the pre-fix build survives and its fork count is
measurable).

## Runs

| run | immucore | shim | result |
| --- | --- | --- | --- |
| `control` | PR (unmodified ISO initrd) | none, real util-linux blkid | boots, login ok |
| `master-tagless` | pre-fix | tagless | **panic, dracut emergency mode** |
| `pr-tagless` | PR | tagless | boots, login ok, `ext4` fallback |
| `master-benign` | pre-fix | benign | boots; `blkid --help` **3x** |
| `pr-benign` | PR | benign | boots; `blkid --help` **1x** |

Full serial logs and screenshots:
https://github.com/ci-forks/kairos/tree/qa-proofs-4462
