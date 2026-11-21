#!/bin/sh
# Tightens sshd_config, validates it, then reloads. Your current session survives a reload.
. "$(dirname "$0")/lib.sh"; need_root
CFG=/etc/ssh/sshd_config
[ -f "$CFG" ] || { warn "No $CFG - is openssh installed?"; exit 1; }
warn "Keep THIS session open. Test a NEW ssh login before closing it."
backup "$CFG"; BAK=$LASTBK
if grep -Eq '^[[:space:]]*Include' "$CFG"; then
  warn "Drop-in configs are included - sshd uses the FIRST value it sees, so these can override us:"
  grep -Hv '^[[:space:]]*#' /etc/ssh/sshd_config.d/*.conf 2>/dev/null | grep -v ':$' | sed 's/^/    /'
fi
set_opt "$CFG" PermitEmptyPasswords no
set_opt "$CFG" MaxAuthTries 3
set_opt "$CFG" LoginGraceTime 30
set_opt "$CFG" X11Forwarding no
set_opt "$CFG" AllowTcpForwarding no
set_opt "$CFG" AllowAgentForwarding no
set_opt "$CFG" PermitTunnel no
set_opt "$CFG" ClientAliveInterval 300
set_opt "$CFG" ClientAliveCountMax 2
set_opt "$CFG" LogLevel VERBOSE
if confirm "Disable root SSH login? (only say yes if another admin user can log in)"; then
  set_opt "$CFG" PermitRootLogin no
fi
say "PasswordAuthentication is left as-is (the scorer probably uses passwords):"
grep -E '^[[:space:]]*PasswordAuthentication' "$CFG"
if sshd -t; then
  rc-service sshd reload && ok "sshd reloaded"
else
  warn "Config invalid - restoring backup"; cp -a "$BAK" "$CFG"
fi
say "Effective settings:"
sshd -T 2>/dev/null | grep -Ei '^(permitrootlogin|passwordauthentication|pubkeyauthentication|maxauthtries|x11forwarding|allowtcpforwarding|permitemptypasswords)'
