#!/bin/sh
# Usage: sh 16_integrity.sh init   (after hardening)   |   sh 16_integrity.sh check
. "$(dirname "$0")/lib.sh"; need_root
S=$HDIR/baseline/integrity.sha; L=$HDIR/baseline/integrity.list
DIRS="/etc /bin /sbin /usr/bin /usr/sbin /usr/local /lib"
case "$1" in
  init)  find $DIRS -xdev -type f 2>/dev/null | grep -Ev '^/etc/(mtab|resolv.conf|hostname)$' | sort > "$L"
         xargs sha256sum < "$L" > "$S" 2>/dev/null; ok "Hashed $(wc -l < "$S") files" ;;
  check) say "Changed or missing:"; sha256sum -c "$S" 2>/dev/null | grep -v ': OK$'
         say "NEW files since init:"
         find $DIRS -xdev -type f 2>/dev/null | grep -Ev '^/etc/(mtab|resolv.conf|hostname)$' | sort | diff "$L" - | grep '^>'
         say "apk's own view of modified files:"; apk audit --system 2>/dev/null | head -40 ;;
  *) echo "Usage: $0 init|check"; exit 1 ;;
esac
