#!/bin/sh
# READ-ONLY end-of-hardening report. Compare against the scoreboard.
. "$(dirname "$0")/lib.sh"; need_root
say "Listening:"; listening
say "SSH effective settings:"; sshd -T 2>/dev/null | grep -Ei '^(permitrootlogin|passwordauthentication|maxauthtries|permitemptypasswords)' | sed 's/^/    /'
say "Firewall INPUT:"; iptables -S INPUT 2>/dev/null | sed 's/^/    /'
say "UID 0 accounts:"; awk -F: '$3==0{print "    "$1}' /etc/passwd
say "Empty passwords:"; awk -F: '$2==""{print "    "$1}' /etc/shadow
have testparm && { testparm -s >/dev/null 2>&1 && ok "smb.conf valid" || warn "smb.conf has errors"; }
say "Service status:"; rc-status 2>/dev/null | sed 's/^/    /'
warn "Now open the Quotient scoreboard: every service should still be green."
