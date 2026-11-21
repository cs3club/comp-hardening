#!/bin/sh
# Tarball of /etc and Samba state so you can roll back a bad change.
. "$(dirname "$0")/lib.sh"; need_root
F="$BK/etc-$(date +%H%M%S).tgz"
tar czf "$F" /etc /var/lib/samba /var/lib/nfs 2>/dev/null
chmod 600 "$F"
ok "Saved $F  (restore: tar xzf $F -C /)"
