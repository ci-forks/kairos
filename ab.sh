#!/bin/bash
# ab.sh m|p : run splash on tty1 at 80x25, grow to 160x64 mid-animation
v=$1; d=$HOME/qa5303; mkdir -p $d/shots
./s "stty -F /dev/tty1 rows 25 cols 80; stty -F /dev/tty1 size; systemctl reset-failed qasplash 2>/dev/null; systemd-run --unit=qasplash -p StandardError=journal /tmp/$v/kairos-splash --tty /dev/tty1 --duration 20s"
sleep 3; python3 qmp.py qmp.sock $d/shots/$v-1-small.ppm >/dev/null
./s "stty -F /dev/tty1 rows 64 cols 160; stty -F /dev/tty1 size"
sleep 3; python3 qmp.py qmp.sock $d/shots/$v-2-grown.ppm >/dev/null
sleep 3; python3 qmp.py qmp.sock $d/shots/$v-3-grown-later.ppm >/dev/null
./s "systemctl is-active qasplash; stty -F /dev/tty1 rows 20 cols 40; stty -F /dev/tty1 size"
sleep 2; python3 qmp.py qmp.sock $d/shots/$v-4-shrunk.ppm >/dev/null
./s "systemctl is-active qasplash; journalctl -u qasplash --no-pager -o short-monotonic | tail -5"
./s "systemctl stop qasplash 2>/dev/null; stty -F /dev/tty1 rows 64 cols 160"
