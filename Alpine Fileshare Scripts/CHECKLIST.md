# First 15 Minutes – kolla (.30, Alpine Fileshare)

Keep a notes file open: time, what you ran, what you changed. Keep **two** SSH sessions to the box.
Scoreboard (Quotient) visible the whole time.

## 0:00 – 2:00  Orient and snapshot
- [ ] Log in with the provided credentials (one session as work shell, one spare). `id`, `hostname`
- [ ] Do NOT touch the router; note the box IP (192.168.220.30 inside / 10.100.1XX.30 from VPN)
- [ ] `sh 01_inventory.sh`  → note which of SMB / NFS / FTP / SSH are really running
- [ ] `sh 02_backup_configs.sh`
- [ ] Check Quotient: which services on this box are green right now?

## 2:00 – 5:00  Accounts (highest-value fix)
- [ ] `sh 04_audit_users.sh`  → extra UID 0? empty passwords? unknown users? unknown `authorized_keys`?
- [ ] `sh 03_change_passwords.sh` (root + all login users + Samba users)
- [ ] Submit Quotient Password Change Requests for every **scored** account you changed
- [ ] `sh 05_lock_user.sh <name>` for accounts nobody can explain (not scored ones!)
- [ ] Remove unknown keys from any `authorized_keys` (edit by hand; note which files)

## 5:00 – 8:00  Remote access
- [ ] `sh 06_harden_ssh.sh`  (answer root-login question carefully)
- [ ] From the spare session: open a NEW ssh login to confirm it works
- [ ] Quotient still green for SSH?

## 8:00 – 11:00  The fileshare services (only those that exist)
- [ ] Samba present → `sh 08_harden_samba.sh`; review each share it prints (guest ok? writable? valid users?)
- [ ] NFS present → `sh 09_harden_nfs.sh`
- [ ] FTP present → `sh 10_harden_ftp.sh`
- [ ] Check Quotient after EACH one. Problem? restore from `/root/hardening/backup/`

## 11:00 – 13:00  Attack surface
- [ ] `sh 11_review_services.sh`  → stop/disable anything legacy or unknown
- [ ] `sh 07_firewall.sh`  → from the spare session type `yes` only if SSH + scoring still work
- [ ] Quotient green?

## 13:00 – 15:00  Lock down, hunt, watch
- [ ] `sh 13_fix_permissions.sh` (read the share-directory findings)
- [ ] `sh 14_sysctl_harden.sh`
- [ ] `sh 12_persistence_hunt.sh` → investigate every hit (cron, odd SUID, tmp binaries, hidden files)
- [ ] `sh 15_logging_audit.sh` (auditd if apk reachable)
- [ ] `sh 16_integrity.sh init`
- [ ] Start monitor in a spare terminal/tmux: `sh 17_watch.sh 20`
- [ ] `sh 18_verify.sh` → confirm results; every service green on Quotient

## Ongoing (every ~10 min)
- [ ] Glance at the watch terminal and `tail /root/hardening/logs/watch.log`
- [ ] `sh 16_integrity.sh check`
- [ ] Re-run `sh 04_audit_users.sh` (new users / keys)
- [ ] Log any compromise evidence for the incident report (time, IP, what changed); file a **detailed** ticket at portal.wccomps.org when needed

## If something breaks
1. Don't panic-reboot. Look at the last thing you changed.
2. Restore the backup copy from `/root/hardening/backup/`, restart that service.
3. Still red? Ticket with details: Scoring Service Check (10 pts) is cheaper than a reset (60 pts).
