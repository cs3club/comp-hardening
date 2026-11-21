#!/bin/sh
# Snapshot "what is on this box" into /root/hardening/baseline for later diffing.
. "$(dirname "$0")/lib.sh"; need_root
B=$HDIR/baseline
say "Host: $(hostname)   OS: $(. /etc/os-release; echo "$PRETTY_NAME")"
ip -4 addr show 2>/dev/null | awk '/inet /{print "    "$2" on "$NF}'
cp /etc/passwd "$B/passwd"; cp /etc/group "$B/group"
listening                                  > "$B/listening.txt"
ps -o pid,user,args                        > "$B/ps.txt"
rc-status -a 2>/dev/null                   > "$B/openrc.txt"
apk info 2>/dev/null | sort                > "$B/packages.txt"
find / -xdev -perm -4000 -type f 2>/dev/null | sort > "$B/suid.txt"
ls -la /etc/crontabs /etc/periodic/* 2>/dev/null > "$B/cron.txt"
mount                                      > "$B/mounts.txt"
sharedirs                                  > "$B/sharedirs.txt"
say "Listening sockets:";           listening
say "Share directories found:";     sed 's/^/    /' "$B/sharedirs.txt"
say "Enabled OpenRC services:";     rc-update show 2>/dev/null | sed 's/^/    /'
say "Samba/NFS/FTP present?"
for p in smbd nmbd nfsd vsftpd proftpd pure-ftpd sshd; do
  pidof "$p" >/dev/null 2>&1 && ok "$p is RUNNING" || echo "    $p not running"
done
ok "Baseline saved in $B"
