#!/bin/sh
# Hardens Samba GLOBAL settings (no guest, no SMB1, no null sessions). Reports risky shares.
. "$(dirname "$0")/lib.sh"; need_root
CONF=/etc/samba/smb.conf
[ -f "$CONF" ] || { warn "No smb.conf - Samba not configured here."; exit 0; }
backup "$CONF"; BAK=$LASTBK
smb_set() {  # key value  (global-only keys; removes old copies, inserts under [global])
  kre=$(echo "$1" | sed 's/ /[[:space:]]+/g')
  sed -E -i "/^[[:space:]]*[;#]?[[:space:]]*$kre[[:space:]]*=/d" "$CONF"
  sed -i "s/^\[global\]/[global]\n    $1 = $2/" "$CONF"
}
smb_set "server min protocol" "SMB2_10"
smb_set "restrict anonymous" "2"
smb_set "map to guest"       "Never"
smb_set "null passwords"     "no"
smb_set "lanman auth"        "no"
smb_set "ntlm auth"          "ntlmv2-only"
smb_set "server signing"     "auto"
if testparm -s >/dev/null 2>&1; then
  ok "smb.conf valid"
  confirm "Restart Samba now? (brief scoring blip)" && { rc-service samba restart || rc-service smbd restart; }
else
  warn "smb.conf invalid - restoring backup"; cp -a "$BAK" "$CONF"
fi
say "Shares allowing guests or writable (review each - edit by hand):"
testparm -s 2>/dev/null | grep -Ei '^\[|path|guest ok|public|writable|read only|valid users' | sed 's/^/    /'
say "Samba users:"; pdbedit -L 2>/dev/null
