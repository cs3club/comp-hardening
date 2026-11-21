#!/bin/sh
# Shared helpers. Sourced by the other scripts - do not run directly.
HDIR=/root/hardening
BK=$HDIR/backup
LOGD=$HDIR/logs
mkdir -p "$BK" "$LOGD" "$HDIR/baseline"
chmod 700 "$HDIR" 2>/dev/null

say()  { printf '[*] %s\n' "$*"; }
ok()   { printf '[+] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
need_root() { [ "$(id -u)" -eq 0 ] || { warn "Run as root (su - or doas sh $0)."; exit 1; }; }
confirm() { printf '%s [y/N] ' "$1"; read -r _a; [ "$_a" = y ] || [ "$_a" = Y ]; }

# backup FILE -> copies to $BK, sets LASTBK to the copy's path
backup() {
  [ -e "$1" ] || return 0
  LASTBK="$BK/$(echo "$1" | tr / _).$(date +%H%M%S)"
  cp -a "$1" "$LASTBK" && ok "Backed up $1 -> $LASTBK"
}

# set_opt FILE KEY VALUE   ("Key value" style, e.g. sshd_config)
set_opt() {
  if grep -Eq "^[#[:space:]]*$2[[:space:]]" "$1"; then
    sed -i -E "s|^[#[:space:]]*$2[[:space:]].*|$2 $3|" "$1"
  else
    echo "$2 $3" >> "$1"
  fi
}
# set_kv FILE KEY VALUE   ("key=value" style, e.g. vsftpd.conf)
set_kv() {
  if grep -Eq "^[#[:space:]]*$2=" "$1"; then
    sed -i -E "s|^[#[:space:]]*$2=.*|$2=$3|" "$1"
  else
    echo "$2=$3" >> "$1"
  fi
}

listening() { if have ss; then ss -tulpn; else netstat -tulpn; fi; }

# exposed -> "proto port" for every listener NOT bound only to loopback
exposed() {
  if have ss; then
    ss -tuln | awk 'NR>1{p=$5;n=split(p,a,":");port=a[n];addr=substr(p,1,length(p)-length(port)-1);
      if(addr!~/^127\./ && addr!~/^\[?::1\]?$/) print $1,port}'
  else
    netstat -tuln | awk 'NR>2{sub(/6$/,"",$1);p=$4;n=split(p,a,":");port=a[n];addr=substr(p,1,length(p)-length(port)-1);
      if(addr!~/^127\./ && addr!="::1") print $1,port}'
  fi | sort -u
}

# sharedirs -> directories exported by Samba / NFS
sharedirs() {
  { awk -F= '/^[[:space:]]*path[[:space:]]*=/{gsub(/[[:space:]]/,"",$2);print $2}' /etc/samba/smb.conf
    awk '$1 ~ /^\//{print $1}' /etc/exports; } 2>/dev/null | sort -u
}
