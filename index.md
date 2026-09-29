# Installer wizard real-boot evidence (Task 10)

ISO: `make iso` (IMAGE_TAG=wizard) at commit 5a7dea40, hadron v0.5.3 standard k3s,
with a hand-built verity `test.sysext.raw` added to the ISO root with xorriso.
QEMU/KVM, SeaBIOS, 40 GiB virtio `vda` plus a 2 GiB virtio `vdb`, grub entry
"kairos (interactive install)" (`install-mode-interactive`).

## web/ (final web run, no cidata, ISO with the null fix)

| File | Shows |
| --- | --- |
| 00-grub-interactive-entry.png | the grub entry that was booted |
| 01-disk.png | Disk step, /dev/vda picked (vda and vdb offered) |
| 02-user.png | User and password step filled |
| 03-ssh-keys.png | SSH keys step with the test key added |
| 04-hostname.png | Hostname wizard-web |
| 05-locale.png | Timezone Europe/Rome, keymap it |
| 06-extensions.png | System extensions: five catalog layers plus `test` from live media |
| 06b-extensions-picked.png | only `test` ticked |
| 07-p2p-settings.png | provider (p2p) step from the provider plugin |
| 08a-finish-default.png | finish step on its default (Nothing) |
| 08b-finish-reboot.png | Reboot picked |
| 10-review.png | Review with the generated cloud-config, no stray "null" line |
| 11-review-edited-top.png | text edited: install.device changed to /dev/vdb, "Edited by hand" tag |
| 12-review-edited-stages.png | hand-added stages.boot entry merged into stages |
| 13-review-confirmed.png | erase confirmation ticked, button still says Install to /dev/vda |
| 13b-regenerate-warning.png | Regenerate with edits asks before replacing them |
| 14-progress-running.png | progress.html during the install |
| 15-progress-done.png | progress.html at "Rebooting node in 5s" |

## web-run1-with-cidata/ (first web run, superseded)

Same flow on the first ISO (commit 8ed487b2). `10-review.png` and
`13-review-confirmed.png` show the defect found here: a stray `null` line under
the Review heading. This run had a cidata cdrom for live SSH, and the agent
merged its `users:` into the install config, so the password check was redone
in the clean run above.

## tui/ (terminal installer on tty1, QMP sendkey)

| File | Shows |
| --- | --- |
| 00-grub-interactive-entry.png | grub entry |
| 01-welcome.png | welcome page with web URLs and QR |
| 02-disk.png | disk step |
| 03-install-options.png | Start Install / Customize Further |
| 04-install-options-reboot-customize.png | finish set to Reboot, Customize Further selected |
| 05-customization-menu.png | optional steps menu |
| 06-user-step.png | user and password filled |
| 07-menu-after-user.png | menu with User ticked |
| 08-ssh-keys-step.png | SSH key being typed (screendump taken while the input was still echoing) |
| 09-hostname-step.png | hostname wizard-tui |
| 10-locale-step.png | locale step, keymap list starts on "(leave unset)" |
| 11-locale-filter-it.png | timezone typed, keymap filtered with `/it` |
| 12-menu-after-locale.png | menu with User, SSH keys, Hostname, Timezone ticked |
| 13-extensions-step.png | catalog layers plus `test (live media)` |
| 14-extensions-test-picked.png | `test` ticked |
| 15-menu-before-finish.png | menu, cursor on Finish Customization |
| 16-summary.png | summary |
| 17-edit-page.png | `e`: the generated cloud-config in the editor |
| 18-edit-page-edited.png | hand-added stages.boot entry and install.device changed to /dev/vdb |
| 19-summary-after-save.png | ctrl+s back on the summary with the "Edited by hand" note |
| 20-view-readonly.png | `v` opens the same editor (read-only only when branding disables advanced) |
| 21-summary-back-from-view.png | esc back to the summary |
| 22-install-progress.png, 23-install-progress-late.png | install progress |
| 24-install-finished.png | last frame before the reboot |
| 25-installed-tty1.png | installed system tty1 |

## mcp/

| File | Shows |
| --- | --- |
| tools-list.txt | MCP tools on the live ISO at /mcp |
| install-call.txt | `install` with a cloud_config adding user mcpuser; the returned cloud_config carries the user and install.device /dev/vda |

## logs/

| File | Shows |
| --- | --- |
| iso-build-proof.txt | sha256 of dist/linux-amd64/kairos-installer equals /system/installer/kairos-installer in the OS image, fill() present, ISO root listing |
| web-cdp-A-steps.txt, web-cdp-B-edit.txt, web-cdp-C-install.txt, web-cdp-D-progress.txt | CDP driver output for the final web run, including the YAML before and after the edit |
| web-installed-check.txt | installed web system: hostname, localtime, vconsole.conf, marker file, lsblk vda/vdb, sysext merged, /oem/90_custom.yaml has device /dev/vda |
| web-serial-login.txt (.raw) | serial console login as kairos with the wizard password |
| tui-installed-check.txt | the same checks for the terminal install |
| tui-serial-login.txt (.raw) | serial console login as kairos with the wizard password |
| make-lint-go.txt | `make lint-go`: timed out loading packages (10 min) in the pinned container |
| lint-pinned-installer-schema.txt | pinned golangci-lint v2.13.2 over ./installer/... ./sdk/schema/... |
| make-test.txt | `make test` output |
| web-run1-with-cidata/ | logs of the superseded first web run, including the sysext debugging |

## Final refresh pass (ISO at 6f4005a8)

### tui-final/ (terminal installer, catalog host blackholed)

| File | Shows |
| --- | --- |
| iso-build-proof.txt | ISO built at 6f4005a8 with a clean worktree; the installer sha256 in dist equals the one in the OS image (2e67a0c9...); strings only this wave added are present |
| live-guest-timing.txt | first boot: kairos-interactive started 22:22:17.84, same installer sha256 in the guest; no route to the internet (restrict=on) |
| blackhole-proof.txt | kairos-io.github.io pointed at 10.0.2.99 and dropped with iptables: curl of the catalog times out after 10 s (rc 28) |
| restart-time.txt | `systemctl start kairos-interactive` at 22:27:13.58; frame changes: cleared screen until 22:27:14.78, welcome at 22:27:14.96 |
| 00a-tty1-cleared-before-start.png, 00b-last-frame-before-welcome.png | tty1 before the installer drew anything |
| 01-welcome-first-frame-blackholed.png | the first welcome frame, about 1.4 s after start, with the catalog blackholed |
| 02-disk.png ... 06-menu-after-hostname.png | disk, install options (Reboot), menu, user, key, hostname |
| 07-extensions-loading.png | "Looking for extensions on the live media and in the catalog..." |
| 08-extensions-loaded.png | after 15.3 s: "No catalog could be read", only `test (live media)` offered |
| extensions-load-time.txt | enter on System extensions to the loaded list: 15.3 s |
| 09-provider-settings.png | "Provider settings" title, mesh gate and k3s both default to No, token help "Used only when the answer above is yes." |
| 10-menu-after-provider.png | menu after submitting the provider step with defaults |
| 11-summary-disk-warning.png | "Everything on /dev/vda will be erased.", Provider settings: Not set, extension shown as "(live media)" |
| 12-view-config-no-p2p.png | `v`: read-only view, no p2p or k3s keys |
| 13-summary-type-y-prompt.png | enter: "Type y to erase /dev/vda and install, any other key to cancel" |
| 14-summary-after-n.png | n: still on the summary, prompt gone |
| 15-install-starting.png | enter then y: install progress |
| installed-check.txt | installed system: hostname wizard-tui-final, /oem/90_custom.yaml has no p2p, network_token or k3s key (grep rc 1), sysext merged |

### web-final/ (web wizard, same ISO, network up)

| File | Shows |
| --- | --- |
| api-wizard-provider.txt | GET /api/wizard: advanced_disabled false; provider fields `p2p.network_token#ask` (bool, default false), `p2p.network_token`, `k3s.enabled` |
| 01-provider-gate-unticked.png | Provider settings with the gate unticked |
| 02-review-no-p2p-no-k3s.png | Review after Next with defaults: no p2p and no k3s keys |
| 03-provider-gate-ticked.png | gate ticked |
| 04-review-gate-ticked-token.png | Review with the generated p2p.network_token |
| 05-provider-gate-unticked-again.png | gate unticked again |
| 06-review-token-gone.png | Review: the token is gone |
| cdp-run.txt | CDP driver output with the YAML of each pass |
