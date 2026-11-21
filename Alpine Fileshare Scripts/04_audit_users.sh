#!/bin/sh
# READ-ONLY. Shows accounts and privileges that deserve a second look.
. "$(dirname "$0")/lib.sh"; need_root
say "Accounts with UID 0 (should be only root):"
awk -F: '$3==0{print "    "$1}' /etc/passwd
say "Accounts with a usable login shell:"
awk -F: '$7 !~ /(nologin|false)$/{print "    "$1"  uid="$3"  shell="$7"  home="$6}' /etc/passwd
say "Accounts with an EMPTY password:"
awk -F: '$2==""{print "    "$1}' /etc/shadow
say "Privileged groups:"
grep -E '^(wheel|adm|root|sudo|disk|shadow|docker):' /etc/group | sed 's/^/    /'
say "doas / sudo rules:"
for f in /etc/doas.conf /etc/doas.d/*.conf /etc/sudoers /etc/sudoers.d/*; do
  [ -f "$f" ] && { echo "  --- $f"; grep -Ev '^[[:space:]]*(#|$)' "$f" | sed 's/^/    /'; }
done
say "authorized_keys files (anyone listed here can log in without a password):"
find / -xdev -name 'authorized_keys*' -type f 2>/dev/null | while read -r f; do
  echo "    $f  ($(grep -c . "$f") keys)"; done
say "Recent logins:"; last 2>/dev/null | head -15
