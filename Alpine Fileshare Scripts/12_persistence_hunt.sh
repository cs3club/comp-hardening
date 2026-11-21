#!/bin/sh
# READ-ONLY hunt for places an attacker hides a way back in.
. "$(dirname "$0")/lib.sh"; need_root
say "Cron jobs:"; for f in /etc/crontabs/*; do [ -f "$f" ] && { echo "  -- $f"; grep -Ev '^[[:space:]]*(#|$)' "$f"; }; done
ls -la /etc/periodic/*/ 2>/dev/null | grep -v '^total' | sed 's/^/    /'
say "Startup hooks:"; ls -la /etc/local.d /etc/profile.d 2>/dev/null | sed 's/^/    /'
grep -Ev '^[[:space:]]*(#|$)' /etc/inittab 2>/dev/null | sed 's/^/    inittab: /'
[ -s /etc/ld.so.preload ] && warn "/etc/ld.so.preload exists: $(cat /etc/ld.so.preload)"
say "Init scripts changed in the last 2 days:"; find /etc/init.d -mtime -2 -type f 2>/dev/null
say "SUID files NOT in your baseline:"
find / -xdev -perm -4000 -type f 2>/dev/null | sort | diff "$HDIR/baseline/suid.txt" - 2>/dev/null | grep '^>'
say "Executables in /tmp /var/tmp /dev/shm:"; find /tmp /var/tmp /dev/shm -type f -perm -u+x 2>/dev/null
say "Hidden files in /root, /home, share dirs:"
find /root /home $(sharedirs) -name '.*' -not -name '.' -not -name '..' -maxdepth 3 2>/dev/null | head -40
say "Files modified in /etc in last 60 min:"; find /etc -mmin -60 -type f 2>/dev/null
say "Shell rc files:"; ls -la /root/.profile /root/.ashrc /root/.bashrc /home/*/.profile /home/*/.ashrc 2>/dev/null
say "Commands run by root (history):"; tail -20 /root/.ash_history /root/.bash_history 2>/dev/null
