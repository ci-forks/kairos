# QA proofs for kairos-io/kairos#4485 (re-QA, PR head 4ec268f7c)

- `boot-livecd-sysrootwait1.mp4` — livecd boot of the unmodified PR ISO through its own
  grub on OVMF/UEFI with `rd.immucore.sysrootwait=1`, the cmdline that failed the
  previous QA cycle. The last frames print the evidence on the VGA console.
- `console-sysrootwait1-evidence.png` — that console: 9 sysroot polls,
  `wait-for-sysroot` 911 ms, hostname `kairos`, the cloud-config `kairos` user present,
  `/oem` populated, 0 step errors.
- `console-livecd-default.png` — default livecd boot of the same ISO.

Logs and measurements: https://gist.github.com/ci-robbot/4afdc83e415362ace9841f29224b1529
