#!/usr/bin/env bash
# QA #4462: boot the PR ISO's kernel with a chosen initrd (PR or master
# immucore + BusyBox blkid shim) and capture evidence.
#
# Direct kernel boot is used, rather than grub off the ISO, because the whole
# point is to swap the initrd. The ISO is still attached as a cdrom, so
# root=live:CDLABEL=COS_LIVE and rootfs.squashfs resolve exactly as they do
# on a real boot.
set -euo pipefail
SKILL=/home/mudler/.claude/skills/testing-immucore-with-qemu
HERE=/tmp/qa4462
: "${INITRD:?set INITRD}"
: "${LOGDIR:?set LOGDIR}"
: "${TIMEOUT:=300}"
: "${SERIAL_PORT:=45611}"
: "${MONITOR_PORT:=45612}"
: "${CMDLINE:=cdroot root=live:CDLABEL=COS_LIVE rd.live.dir=/ rd.live.squashimg=rootfs.squashfs rd.live.overlay.overlayfs net.ifnames=1 console=ttyS0 console=tty1 kairos.ram kairos.ram.create_partitions nomodeset selinux=0 rd.immucore.debug ignore_loglevel}"

WORK="$(mktemp -d)"
trap 'kill -9 "${qpid:-}" 2>/dev/null || true; rm -rf "$WORK"' EXIT
rm -rf "$LOGDIR"; mkdir -p "$LOGDIR"

mkdir "$WORK/cidata"
cp "$SKILL/scripts/userdata-login.yaml" "$WORK/cidata/user-data"
printf 'instance-id: qa4462\n' > "$WORK/cidata/meta-data"
xorriso -as mkisofs -V cidata -J -R -o "$WORK/cidata.iso" "$WORK/cidata" >/dev/null 2>&1

DISK="$WORK/disk.qcow2"
qemu-img create -f qcow2 "$DISK" 4G >/dev/null

echo ">>> booting initrd=${INITRD##*/}"
echo ">>> cmdline: $CMDLINE"
qemu-system-x86_64 \
  -enable-kvm -cpu host -m 3G -smp 2 \
  -kernel "$HERE/kernel" -initrd "$INITRD" -append "$CMDLINE" \
  -drive "file=$HERE/test.iso,format=raw,if=ide,media=cdrom,readonly=on" \
  -drive "file=$WORK/cidata.iso,format=raw,if=ide,media=cdrom,readonly=on" \
  -drive "file=$DISK,format=qcow2,if=virtio" \
  -vga std -display none \
  -monitor "telnet:127.0.0.1:${MONITOR_PORT},server,nowait" \
  -serial "telnet:127.0.0.1:${SERIAL_PORT},server,nowait" \
  > "$LOGDIR/qemu.log" 2>&1 &
qpid=$!

sleep 3
rc=0
TIMEOUT="$TIMEOUT" LOGIN_USER="${LOGIN_USER:-kairos}" LOGIN_PASS="${LOGIN_PASS:-kairos}" \
CHECK_CMD="${CHECK_CMD:-}" SCREENDUMP="$LOGDIR/failure-screen" \
python3 "${DRIVER:-$SKILL/scripts/login_check.py}" "$SERIAL_PORT" "$MONITOR_PORT" "$WORK/serial.raw.log" || rc=$?
# grab a screendump unconditionally, so a PASS boot has a picture too
(printf 'screendump %s\n' "$LOGDIR/final-screen.ppm"; sleep 2; printf 'quit\n') \
  | timeout 15 telnet 127.0.0.1 "$MONITOR_PORT" >/dev/null 2>&1 || true
sleep 1
kill -9 "$qpid" 2>/dev/null || true
wait "$qpid" 2>/dev/null || true

tr -d '\r' < "$WORK/serial.raw.log" | strings > "$LOGDIR/boot-serial.log"
awk '/BEGIN_IMMUCORE_LOG/{f=1;next} /END_IMMUCORE_LOG/{f=0} f' "$LOGDIR/boot-serial.log" > "$LOGDIR/immucore.log"
awk '/BEGIN_JOURNAL/{f=1;next} /END_JOURNAL/{f=0} f'           "$LOGDIR/boot-serial.log" > "$LOGDIR/journalctl.log"
awk '/BEGIN_CHECK/{f=1;next} /END_CHECK/{f=0} f'               "$LOGDIR/boot-serial.log" > "$LOGDIR/check.log"
for m in PANIC SHIMCOUNT STATUS; do
  awk -v b="BEGIN_$m" -v e="END_$m" '$0 ~ b {f=1;next} $0 ~ e {f=0} f' "$LOGDIR/boot-serial.log" > "$LOGDIR/$(echo $m | tr A-Z a-z).log"
done
for p in "$LOGDIR"/*.ppm; do
  [[ -f "$p" ]] && ffmpeg -loglevel error -y -i "$p" "${p%.ppm}.png" && rm -f "$p"
done
find "$LOGDIR" -maxdepth 1 -empty -delete
echo ">>> exit=$rc; evidence in $LOGDIR:"; ls -la "$LOGDIR"
exit "$rc"
