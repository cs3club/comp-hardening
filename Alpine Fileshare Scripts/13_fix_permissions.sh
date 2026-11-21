#!/bin/sh
# Resets permissions on sensitive files and reports risky ones in the share directories.
. "$(dirname "$0")/lib.sh"; need_root
chmod 644 /etc/passwd /etc/group
chown root:shadow /etc/shadow 2>/dev/null || chown root:root /etc/shadow
chmod 640 /etc/shadow
[ -f /etc/ssh/sshd_config ] && chmod 600 /etc/ssh/sshd_config
[ -f /etc/doas.conf ] && chmod 600 /etc/doas.conf
[ -f /etc/sudoers ] && chmod 440 /etc/sudoers
[ -d /etc/crontabs ] && chmod 700 /etc/crontabs
chmod 700 /root
ok "Core file permissions reset"
say "World-writable files in /etc:"; find /etc -xdev -type f -perm -002 2>/dev/null
for d in $(sharedirs); do
  [ -d "$d" ] || continue
  say "Share $d  (owner/mode: $(ls -ld "$d" | awk '{print $1,$3,$4}'))"
  echo "  world-writable files:"; find "$d" -type f -perm -002 2>/dev/null | head -20
  echo "  SUID/SGID files (should be none):"; find "$d" \( -perm -4000 -o -perm -2000 \) -type f 2>/dev/null
  echo "  executables:"; find "$d" -type f -perm -u+x 2>/dev/null | head -20
done
