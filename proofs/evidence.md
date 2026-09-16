# QA evidence — kairos-io/kairos#4588 (re-verification on the merged head)

## Why this run

The earlier QA PASS (comment 2026-09-16T16:44Z) tested head `a058adecb`, which
was based on master `b4f7012c1`. Master then gained
`13f0e1c0 feat(installer): serve the web UI from the installer, one process per boot (#4574)`
and `edb4d907 fix(immucore): show the halt reason on every console (#4653)`, and
master was merged into this PR at 2026-09-16T19:02Z as `a2e4ca9a`.

#4574 rewrites the installer dispatcher and `interactive_install.go`, which is
exactly the code this PR changes, so the tested artifact and the mergeable head
were no longer the same thing. This run re-tests `a2e4ca9a`.

## Build

    git worktree add --detach /tmp/qa4588 refs/qa/4588      # a2e4ca9a
    go build ./...                                          # OK
    go test ./agent/pkg/cmd/... ./agent/internal/agent/...   # all ok
    VERSION=v0.0.0-qa4588m scripts/build-iso.sh

ISO: kairos-hadron-v0.5.1-standard-amd64-generic-v0.0.0-qa4588m-k3sv1.36.4+k3s1.iso
(base ghcr.io/kairos-io/hadron:v0.5.1, amd64 standard, k3s v1.36.4+k3s1)

## Harness

Direct kernel boot of the ISO's own kernel/initrd, using each GRUB menuentry's
verbatim cmdline (taken from the built ISO's /boot/grub2/grub.cfg), a 30 GiB
virtio disk, and the config delivered as a `cidata` cdrom. QEMU/KVM, 4 GiB, 4 vCPU.

Interactive entry cmdline (grub.cfg line 46, unmodified apart from the appended
scenario token):

    cdroot root=live:CDLABEL=COS_LIVE rd.live.dir=/ rd.live.squashimg=rootfs.squashfs \
    net.ifnames=1 console=ttyS0 console=tty1 rd.cos.disable vga=795 nomodeset \
    install-mode-interactive selinux=0 rd.live.overlay.overlayfs

Config on the cidata cdrom:

    #cloud-config
    install:
      auto: true
      device: /dev/vda
      reboot: false
      poweroff: true      # (false in the A2/C/E/F runs, so the VM stays up)
    users:
      - name: kairos
        passwd: kairos
        groups: [admin]

## Scenarios and results

| # | boot entry | config | expected | observed | disk after |
| - | ---------- | ------ | -------- | -------- | ---------- |
| A | `install-mode-interactive` | `install.auto: true` | unattended install, no TUI | installed, powered itself off at 22.9s | 1.94 GB, full COS layout |
| B | `install-mode-interactive` + `kairos.skip-auto-install` | `install.auto: true` | installer TUI, no install | disk-selection TUI on tty1 | 197 KB (untouched) |
| C | `install-mode` (default entry) | `install.auto: true` | unchanged, unattended install | installed | 1.94 GB |
| D | `install-mode-interactive` | none | installer TUI | disk-selection TUI on tty1 | 197 KB (untouched) |

Row C is the regression check that matters for `tests/tests_suite_test.go`:
the default entry still installs unattended after the `agent.AutoInstall` /
`agent.Install(cc, ...)` split.

Row D is the regression check that an interactive boot with nothing unattended
to honour still reaches the installer.

## Scenario A — partition table written by the interactive entry

    $ lsblk -o NAME,SIZE,FSTYPE,LABEL /dev/nbd0
    nbd0       30G
    |-nbd0p1    1M
    |-nbd0p2   64M ext4   COS_OEM
    |-nbd0p3  1.4G ext4   COS_RECOVERY
    |-nbd0p4  2.9G ext4   COS_STATE
    `-nbd0p5 25.6G ext4   COS_PERSISTENT

The cidata config was consumed and persisted to COS_OEM/90_custom.yaml:

    #cloud-config
    # Sources:
    # - /oem/95_userdata/userdata.yaml
    # - reader
    # - cmdline
    install:
        auto: true
        device: /dev/vda
        poweroff: true
        reboot: false
    ...

Serial log, scenario A (the unattended install ran to completion and honoured
`poweroff: true` without any prompt):

    Broadcast message from root@kairos on tty1 (Wed 2026-09-16 20:05:23 UTC):
    The system will power off now!
    [   22.920452] systemd-shutdown[1]: Could not detach loopback /dev/loop0: Resource busy
    [   22.936674] reboot: Power down

## Scenario A — the unit that did it

`52_installer.yaml` gives `kairos-interactive.service` a fixed
`ExecStart=/usr/bin/kairos-agent interactive-install --shell`. In run F, with
the install finished:

    # systemctl show kairos-interactive -p Result -p ExecMainStatus -p ActiveState
    ActiveState=activating      (parked on the "press enter" prompt)
    Result=success
    ExecMainStatus=0

    # lsblk -o NAME,LABEL /dev/vda
    vda
    |-vda1
    |-vda2 COS_OEM
    |-vda3 COS_RECOVERY
    |-vda4 COS_STATE
    `-vda5 COS_PERSISTENT

So the interactive unit, invoked with `--shell`, performed a full unattended
install and exited 0. `journalctl -u kairos-interactive` contains no
"Welcome to the Interactive installation" banner, consistent with the TUI never
being reached.

## Screenshots

See the linked image branch:

- `autoA2.png`  — scenario A, tty1: install stages running to
  "Installation completed", no disk-selection screen at any point
- `skipB.png`   — scenario B, tty1: "Welcome to the Interactive installation.
  Select target disk for installation:" despite `install.auto: true`
- `noconfD.png` — scenario D, tty1: same TUI with no config present

## Not covered

- UEFI/secure-boot install. These boots are BIOS (direct kernel boot, no OVMF),
  so partition 1 is a 1 MiB BIOS boot partition rather than an ESP. The branch
  under test runs before any firmware-specific code, so this is orthogonal.
- The `--shell was ignored` warning is emitted by the CLI to the unit's stdout,
  which `52_installer.yaml` points at tty1 rather than the journal, so it was
  not captured as text. Its guard is the same `installed` value proven above.
- `KAIROS_SKIP_AUTO_INSTALL` and the bare `--skip-auto-install` flag were not
  exercised on a live boot; the cmdline spelling was, which is the one an
  operator can actually reach from a booted ISO.
