# QA proofs, kairos-io/kairos#4588

PR head `a058adec`. See `proofs/QA-LOG.md` for the full transcript.

| file | what it shows |
| --- | --- |
| `proofs/t1-frame-0006.png`, `t1-frame-0008.png` | interactive entry + `install.auto: true`: tty1 runs the unattended install (partitioning, active.img, GRUB, recovery copy), no installer TUI |
| `proofs/t1-interactive-auto-install.mp4` | the same boot, start to poweroff |
| `proofs/t3-tui-shown.png` | same ISO, same config, plus `kairos.skip-auto-install`: the installer TUI is shown and nothing is installed |
| `proofs/t3-skip-flag-tui.mp4` | the same boot |
| `proofs/t4-frame-0008.png`, `t4-installmode-auto-90s.png` | `install-mode` (default) entry still installs unattended after the `Install(cc, ...)` refactor |
| `proofs/t5-interactive-noauto-90s.png` | interactive entry, config without `install.auto`: installer TUI, disk untouched |
| `proofs/t6-installed-boot.png` | the system the interactive entry installed unattended boots to a login prompt |
