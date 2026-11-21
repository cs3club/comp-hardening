#!/bin/sh
# LIVE MONITOR - run in its own terminal (or tmux). Prints and logs anything that changes:
# listeners, connections, processes, logged-in sessions, users, key config/auth files, share-dir files,
# plus ssh/samba/doas/firewall log lines.   Usage: sh 17_watch.sh [interval_seconds]
. "$(dirname "$0")/lib.sh"; need_root
INT=${1:-20}; W=$HDIR/.watch; LOG=$LOGD/watch.log; mkdir -p "$W"
alert() { m="$(date '+%F %T') $*"; printf '\033[1;31m%s\033[0m\n' "$m"; echo "$m" >> "$LOG"; }

snap_ports()    { exposed; }
snap_conns()    { if have ss; then ss -tn | awk '$1=="ESTAB"{print $5" "$4}'; else netstat -tn | awk '/ESTABLISHED/{print $5" "$4}'; fi |
                  awk '{s=$1;sub(/:[0-9]+$/,"",s);p=$2;sub(/.*:/,"",p);print s" -> local port "p}' | sort -u; }
snap_procs()    { ps -o user,comm | grep -v '^USER' | grep -Ev ' (ps|sleep|diff|grep|sort|awk|wc|tail|cat|sed|mv|date)$' | sort -u; }
snap_sessions() { who | awk '{print $1,$2}' | sort; }
snap_users()    { cut -d: -f1,3,6,7 /etc/passwd; }
snap_files()    { for f in /etc/passwd /etc/shadow /etc/group /etc/ssh/sshd_config /etc/samba/smb.conf /etc/exports \
                    /etc/doas.conf /etc/sudoers /etc/hosts /etc/crontabs/* /etc/profile.d/* /etc/local.d/*; do
                    [ -f "$f" ] && sha256sum "$f"; done
                  find /root /home -name 'authorized_keys*' -exec sha256sum {} + 2>/dev/null; }
snap_share()    { d=$(sharedirs); [ -n "$d" ] && find $d -type f 2>/dev/null | sort; }

SNAPS="ports conns procs sessions users files share"
LOGPOS=$(wc -l < /var/log/messages 2>/dev/null || echo 0)
for s in $SNAPS; do snap_$s > "$W/$s.base" 2>/dev/null; done
ok "Watching every ${INT}s - Ctrl-C to stop. Log: $LOG"
while :; do
  sleep "$INT"
  for s in $SNAPS; do
    snap_$s > "$W/$s.new" 2>/dev/null
    diff "$W/$s.base" "$W/$s.new" | grep '^[<>]' | while read -r l; do
      case "$l" in '>'*) alert "NEW  [$s] ${l#> }";; *) alert "GONE [$s] ${l#< }";; esac
    done
    mv "$W/$s.new" "$W/$s.base"
  done
  if [ -f /var/log/messages ]; then
    n=$(wc -l < /var/log/messages); [ "$n" -lt "$LOGPOS" ] && LOGPOS=0
    tail -n +$((LOGPOS+1)) /var/log/messages | grep -Ei 'sshd.*(Failed|Accepted|Invalid|error)|smbd.*(auth|fail|denied)|doas|su\[|FW-DROP' |
      while read -r l; do alert "LOG  $l"; done
    LOGPOS=$n
  fi
done
