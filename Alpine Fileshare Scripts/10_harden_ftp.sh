#!/bin/sh
# Disables anonymous FTP (anonymous FTP is not scored per the packet). vsftpd only; others reported.
. "$(dirname "$0")/lib.sh"; need_root
for p in proftpd pure-ftpd; do pidof $p >/dev/null 2>&1 && warn "$p is running - harden by hand (disable anonymous)"; done
C=/etc/vsftpd/vsftpd.conf; [ -f "$C" ] || C=/etc/vsftpd.conf
[ -f "$C" ] || { warn "No vsftpd config found."; exit 0; }
backup "$C"
set_kv "$C" anonymous_enable NO
set_kv "$C" ftpd_banner "Authorized use only"
set_kv "$C" xferlog_enable YES
rc-service vsftpd restart && ok "vsftpd restarted with anonymous disabled"
