#!/bin/sh
# Host firewall: default-deny INPUT, allow only ports that are currently listening.
# Has an AUTO-ROLLBACK: if you do not confirm within 90s, rules are opened again.
# This is the BOX firewall only - never touch the OpenWRT router from here.
. "$(dirname "$0")/lib.sh"; need_root
have iptables || { say "Installing iptables"; apk add iptables ip6tables || exit 1; }
PORTS=$(exposed)
for p in $EXTRA_TCP; do PORTS="$PORTS
tcp $p"; done
say "Will ALLOW inbound (proto port):"; echo "$PORTS" | sed 's/^/    /'
warn "Remove anything you don't recognise from the service first (script 11). NFS helper ports can change after a restart."
confirm "Apply these rules?" || exit 0
( sleep 90; iptables -P INPUT ACCEPT; iptables -F INPUT; ip6tables -P INPUT ACCEPT 2>/dev/null ) >/dev/null 2>&1 &
RB=$!
FAIL=0
ipt() { iptables "$@" || { warn "rule failed: $*"; FAIL=1; }; }
ipt -F INPUT
ipt -A INPUT -i lo -j ACCEPT
ipt -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
ipt -A INPUT -p icmp --icmp-type echo-request -m limit --limit 10/second -j ACCEPT
echo "$PORTS" | while read -r pr po; do
  [ -n "$po" ] && iptables -A INPUT -p "$pr" --dport "$po" -j ACCEPT
done
iptables -A INPUT -m limit --limit 6/min -j LOG --log-prefix "FW-DROP: " 2>/dev/null
if [ "$FAIL" -eq 0 ]; then iptables -P INPUT DROP; else warn "Not setting DROP policy"; fi
if have ip6tables; then
  ip6tables -F INPUT; ip6tables -A INPUT -i lo -j ACCEPT
  ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  ip6tables -P INPUT DROP
fi
say "From a SECOND terminal, confirm ssh works and the scoreboard is still green."
printf "Type yes within 90s to keep these rules: "; read -r a
if [ "$a" = yes ]; then
  kill "$RB" 2>/dev/null
  rc-service iptables save; rc-update add iptables default
  have ip6tables && { rc-service ip6tables save; rc-update add ip6tables default; }
  ok "Rules saved and enabled at boot"
else
  warn "Not confirmed - rollback timer will open the firewall"
fi
