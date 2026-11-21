#!/bin/sh
# Usage: sh 05_lock_user.sh user [user...]   - locks password, sets shell to nologin, kills sessions.
# Reversible. Do NOT lock accounts Quotient uses.
. "$(dirname "$0")/lib.sh"; need_root
[ $# -ge 1 ] || { echo "Usage: $0 user [user...]"; exit 1; }
backup /etc/passwd; backup /etc/shadow
for u in "$@"; do
  [ "$u" = root ] && { warn "Refusing to lock root"; continue; }
  id "$u" >/dev/null 2>&1 || { warn "No such user: $u"; continue; }
  passwd -l "$u" >/dev/null
  sed -i "s#^\($u:.*:\)[^:]*\$#\1/sbin/nologin#" /etc/passwd
  for p in $(ps -o pid,user | awk -v u="$u" '$2==u{print $1}'); do kill -9 "$p" 2>/dev/null; done
  ok "Locked $u (undo: passwd -u $u and restore shell from $BK)"
done
