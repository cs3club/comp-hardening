#!/bin/sh
# Makes sure logs exist, then (optionally) installs auditd with watches on key files.
. "$(dirname "$0")/lib.sh"; need_root
rc-service syslog status >/dev/null 2>&1 || { rc-service syslog start; rc-update add syslog boot; }
ok "syslog running -> /var/log/messages (ssh/samba/doas events land here)"
confirm "Install and configure auditd? (needs apk network access)" || exit 0
have auditctl || apk add audit || { warn "apk failed (no repo access?)"; exit 1; }
mkdir -p /etc/audit/rules.d
cat > /etc/audit/rules.d/hardening.rules <<'EOF'
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/doas.conf -p wa -k priv
-w /etc/sudoers -p wa -k priv
-w /etc/ssh/sshd_config -p wa -k sshcfg
-w /etc/samba/smb.conf -p wa -k smbcfg
-w /etc/exports -p wa -k nfscfg
-w /etc/crontabs -p wa -k cron
-w /root/.ssh -p wa -k rootssh
EOF
confirm "Also log EVERY command executed (noisy, but shows exactly what attackers run)?" && \
  echo '-a always,exit -F arch=b64 -S execve -k exec' >> /etc/audit/rules.d/hardening.rules
rc-update add auditd default; rc-service auditd restart
auditctl -R /etc/audit/rules.d/hardening.rules 2>/dev/null
ok "Query with: ausearch -k identity | aureport -f -i     (keys: identity priv sshcfg smbcfg nfscfg cron exec)"
