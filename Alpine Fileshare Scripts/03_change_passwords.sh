#!/bin/sh
# Interactively change passwords for root and every account with a login shell.
. "$(dirname "$0")/lib.sh"; need_root
warn "SCORED accounts: Quotient logs in with the OLD password until you submit"
warn "a Password Change Request in the scoring engine. Do both, or checks fail."
warn "Non-scored accounts (root, extra users): change freely."
for u in $(awk -F: '($3==0||$3>=1000) && $7 !~ /(nologin|false)$/ {print $1}' /etc/passwd); do
  if confirm "Change password for '$u'?"; then passwd "$u"; fi
done
if have pdbedit; then
  say "Samba accounts (separate from system passwords):"
  pdbedit -L
  for u in $(pdbedit -L | cut -d: -f1); do
    confirm "Change SAMBA password for '$u'?" && smbpasswd "$u"
  done
fi
ok "Done. Remember the Quotient password-change request for scored accounts."
