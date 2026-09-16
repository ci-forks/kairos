# QA log, kairos-io/kairos#4588

PR head `a058adecb70d727bd1eb7972498c62ff72060b40` (3 commits: 12168d513, 82eff5ddc, a058adecb).
Base: `master` `b4f7012c1`.

## Build

    VERSION=v0.0.0-qa4588 scripts/build-iso.sh
    BASE_IMAGE=ghcr.io/kairos-io/hadron:v0.5.1  ARCH=amd64  MODEL=generic  KUBERNETES_DISTRO=k3s
    -> kairos-hadron-v0.5.1-standard-amd64-generic-v0.0.0-qa4588-k3sv1.36.4+k3s1.iso (416 MB)

ISO grub entries (from /boot/grub2/grub.cfg on the built ISO):

    entry 0  "Kairos"                       -> install-mode                (default)
    entry 1  "Kairos (manual)"              -> no install token
    entry 2  "kairos (interactive install)" -> install-mode-interactive

Every VM below boots the ISO's own kernel+initrd directly with the exact cmdline
the matching grub entry uses, so the entry under test is unambiguous. Two cdroms:
the ISO and a CIDATA disc carrying the cloud config. Disk: 25G virtio qcow2.
QEMU/KVM, 4 vCPU, 4 GiB.

## Cloud config used for the install.auto cases

    #cloud-config
    install:
      auto: true
      device: /dev/vda
      reboot: false
      poweroff: true
    users:
      - name: kairos
        passwd: kairos
        groups: [admin]
    stages:
      initramfs:
        - name: "qa: root shell on ttyS1"     # QA-only, so the harness can read
          ...                                 # the journal without touching tty1

## Unit tests

    $ go test ./agent/internal/agent/ ./agent/pkg/cmd/
    ok   github.com/kairos-io/kairos/v4/agent/internal/agent   2.674s
    ok   github.com/kairos-io/kairos/v4/agent/pkg/cmd          0.017s

## T1  interactive entry + install.auto: true      -> unattended install

tty1 shows the unattended install, never an installer TUI:

    Partitioning device...
    Creating partition table for partition type gpt
    Running before-install hook
    Creating file system image /run/cos/state/cOS/active.img with size 638MiB
    Copying /run/rootfsbase source to /run/cos/active
    Installing GRUB..
    Grub install to device /dev/vda complete
    Copying /run/cos/state/cOS/active.img source to /run/cos/recovery/cOS/recovery.img
    Starting unified encryption flow
    Running CopyLogs hook

then, from tty1: "The system will power off now!" (poweroff: true honoured).

Disk after:

    NAME      SIZE FSTYPE LABEL
    nbd0       25G
    |-nbd0p1    1M
    |-nbd0p2   64M ext4   COS_OEM
    |-nbd0p3  1.4G ext4   COS_RECOVERY
    |-nbd0p4  2.8G ext4   COS_STATE
    `-nbd0p5 20.6G ext4   COS_PERSISTENT

    COS_STATE/cOS: active.img 668991488, passive.img 668991488

## T3  interactive entry + install.auto: true + kairos.skip-auto-install  -> installer

Same ISO, same config, one extra cmdline token. Installer TUI is shown and the
disk is never touched (qcow2 stays at 197008 bytes, i.e. empty).

    $ cat /proc/cmdline
    ... install-mode-interactive kairos.skip-auto-install

    $ journalctl -u kairos-interactive --no-pager
    systemd[1]: Starting kairos interactive-installer...
    kairos-agent[1459]: --skip-auto-install was given, so install.auto is ignored and the installer runs
    kairos-agent[1459]: Delegating interactive installation to /system/installer/kairos-installer
    kairos-installer[1467]: Discovering interactive-install check plugins

## T4  install-mode entry (default) + install.auto: true  -> unattended install

Regression check on the Install(cc, ...) refactor (Install no longer scans; it
takes AutoInstall's config). Installed and powered off, same partition layout
as T1:

    |-nbd0p2   64M ext4   COS_OEM
    |-nbd0p3  1.4G ext4   COS_RECOVERY
    |-nbd0p4  2.8G ext4   COS_STATE
    `-nbd0p5 20.6G ext4   COS_PERSISTENT

    systemd-shutdown[1]: ...
    reboot: Power down

## T5  interactive entry + config WITHOUT install.auto  -> installer

Installer TUI shown, disk untouched. Delegation still works by default.

## Opt-out routes, all three, on a live system carrying install.auto: true

Bench: a live boot with install.auto: true in /oem, and KAIROS_INSTALLER pointed
at a stub that prints FAKE-INSTALLER-RAN, so "delegated" and "installed" are
distinguishable.

    1. --skip-auto-install flag
       $ KAIROS_INSTALLER=/tmp/fake kairos-agent interactive-install --skip-auto-install
       FAKE-INSTALLER-RAN

    2. env var
       $ KAIROS_INSTALLER=/tmp/fake KAIROS_SKIP_AUTO_INSTALL=true kairos-agent interactive-install
       FAKE-INSTALLER-RAN

    3. kernel cmdline: covered by T3 above.

    default, no opt-out:
       $ KAIROS_INSTALLER=/tmp/fake kairos-agent interactive-install --shell
       $ grep -c FAKE-INSTALLER-RAN /tmp/o3.log
       0
       ... Installation completed ...
       -> full COS_OEM/COS_RECOVERY/COS_STATE/COS_PERSISTENT layout on /dev/vda

The flag is discoverable and documents all three forms:

    $ kairos-agent interactive-install --help
    OPTIONS:
       --shell                (default: false)
       --skip-auto-install    Open the installer even when the config sets install.auto,
                              instead of installing unattended. Also settable on the boot
                              cmdline as kairos.skip-auto-install, which is how to reach it
                              from a booted ISO. (default: false) [$KAIROS_SKIP_AUTO_INSTALL]

## T6  boot the system the interactive entry installed unattended

    kairos-5487 login:
    $ ssh -p 2288 kairos@127.0.0.1
    kairos-5487
    kairos v0.0.0-qa4588
    KAIROS_FAMILY="hadron"
    KAIROS_FLAVOR="hadron"

    $ sudo kairos-agent state
    persistent:
        mounted: true
        name: /dev/vda5
        filesystemlabel: COS_PERSISTENT
        mount_point: /usr/local

## T7  A/B, master vs PR head, same live system, same config, same stub

One live boot, /oem/95_userdata/userdata carrying install.auto: true, both
binaries present (master fetched in on a third cdrom).

    A, before (master b4f7012c):
      $ /mnt/mb/kairos --version
      kairos master-b4f7012c
      $ KAIROS_INSTALLER=/tmp/fake /mnt/mb/kairos agent interactive-install
      FAKE-INSTALLER-RAN                       <- install.auto ignored: the reported bug

    B, after (PR head, the agent on the ISO):
      $ KAIROS_INSTALLER=/tmp/fake kairos-agent interactive-install
      $ grep -ac FAKE-INSTALLER-RAN /tmp/oB.log
      0                                        <- installer never reached
      ... Powering off node in 5s, press Ctrl+C to cancel
      ... Shutdown node
      EXIT=0
      $ lsblk -o NAME,LABEL /dev/vda
      vda
      |-vda1
      |-vda2 COS_OEM
      |-vda3 COS_RECOVERY
      |-vda4 COS_STATE
      `-vda5 COS_PERSISTENT

## Observations, none of them blocking

1. install.auto with neither reboot nor poweroff set still stops at an
   interactive prompt: "Installation completed, press enter to go back to the
   shell. [Yes/no/all/cancel]". That is a verbatim extraction of master's
   install-mode branch, so it is not a regression, and the two entries now behave
   identically. Worth naming only because the PR's stated goal is that the live
   CD must not stop at a prompt with nobody there to answer it, and in that one
   config shape it still does, on both entries.

2. The "--shell was ignored" warning is printed after that prompt returns, so on
   a no-reboot/no-poweroff unattended boot nobody sees it until the prompt is
   answered. Cosmetic.

3. Unrelated to this PR: kairos-interactive.service logs
   "Unable to locate executable '/usr/bin/kill': No such file or directory" for
   its ExecStartPre. /usr/bin/kill does not exist on hadron. The line is prefixed
   with "-" so it is ignored; it comes from master's
   kairos-init/pkg/bundled/cloudconfigs/52_installer.yaml.
