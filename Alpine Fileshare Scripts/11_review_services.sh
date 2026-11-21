#!/bin/sh
# Flags legacy / unneeded services and offers to stop + disable each one.
. "$(dirname "$0")/lib.sh"; need_root
say "Everything reachable from the network:"; listening
say "Enabled OpenRC services:"; rc-update show | sed 's/^/    /'
BAD="telnetd telnet inetd xinetd rsh rlogin rexec tftpd vnc x11vnc cupsd cups avahi-daemon avahi snmpd"
for s in $BAD; do
  if [ -e "/etc/init.d/$s" ] || pidof "$s" >/dev/null 2>&1; then
    warn "Found: $s"
    if confirm "  Stop and disable $s?"; then
      rc-service "$s" stop 2>/dev/null; rc-update del "$s" 2>/dev/null
      pidof "$s" >/dev/null 2>&1 && killall "$s"
    fi
  fi
done
say "Anything listening that is NOT ssh/smb/nfs/ftp deserves a question - check the PID above:"
say "  ls -l /proc/<pid>/exe   and   cat /proc/<pid>/cmdline"
