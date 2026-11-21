#!/bin/sh
# Kernel/network hardening via /etc/sysctl.d. Safe for a non-router host.
. "$(dirname "$0")/lib.sh"; need_root
F=/etc/sysctl.d/99-hardening.conf
cat > "$F" <<'EOF'
net.ipv4.ip_forward = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv6.conf.all.accept_redirects = 0
kernel.randomize_va_space = 2
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
fs.suid_dumpable = 0
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
EOF
sysctl -p "$F" 2>&1 | sed 's/^/    /'
rc-update add sysctl boot 2>/dev/null
ok "Applied and set to persist ($F)"
