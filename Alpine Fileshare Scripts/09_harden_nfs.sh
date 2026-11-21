#!/bin/sh
# Audits /etc/exports; optionally fixes no_root_squash and narrows wildcards.
. "$(dirname "$0")/lib.sh"; need_root
X=/etc/exports
[ -s "$X" ] || { warn "No exports configured."; exit 0; }
backup "$X"
say "Current exports:"; grep -Ev '^[[:space:]]*(#|$)' "$X" | sed 's/^/    /'
grep -q 'no_root_squash' "$X" && { warn "no_root_squash found (remote root = local root)";
  confirm "Change to root_squash?" && sed -i 's/no_root_squash/root_squash/g' "$X"; }
grep -Eq '(\*|0\.0\.0\.0/0)' "$X" && { warn "Wildcard client found - anyone can mount";
  printf "Enter allowed network in CIDR (blank = skip): "; read -r N
  [ -n "$N" ] && sed -i -E "s#(^|[[:space:]])(\*|0\.0\.0\.0/0)\(#\1$N(#g" "$X"; }
have exportfs && { exportfs -ra && ok "Exports reloaded"; exportfs -v; }
