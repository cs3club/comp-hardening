# kolla (.30) – Alpine Fileshare Hardening Kit

Small, single-purpose POSIX `sh` scripts (Alpine uses BusyBox `ash`; no bash needed).
Run them **one at a time**, as root, read the output, then move on.
Everything is logged/backed up under `/root/hardening/` (`backup/`, `baseline/`, `logs/`).

## Getting the scripts onto the box
- From your VPN machine: `scp -r kolla-hardening root@10.100.1XX.30:/root/` (try `scp -O` if scp complains about sftp), or
- `python3 -m http.server 8000` on your machine and `wget -r -np http://<your-vpn-ip>:8000/` on kolla.
Then: `cd /root/kolla-hardening && sh 01_inventory.sh`

## Golden rules
1. **Scored accounts:** a password changed on the box must ALSO be submitted as a Password Change Request in Quotient, or checks fail. Non-scored accounts can change freely.
2. **Keep a second SSH session open** while changing SSH, firewall, or Samba.
3. Don't touch the OpenWRT router (`vigra`, .2) from these scripts. A bad router change costs -100 per reset.
4. Fileshare is scored on *something* (SMB/NFS/FTP/SSH likely) – script 01 shows what is actually running. Only harden what exists.
5. If a service goes red after a change: restore from `/root/hardening/backup/`, then file a detailed ticket if needed.

## Scripts

| # | Script | What it does | Changes system? |
|---|--------|--------------|-----------------|
| – | `lib.sh` | Shared helpers (logging, backups, config editing). Sourced by the others. | No |
| 01 | `01_inventory.sh` | Saves a baseline of users, listeners, processes, services, packages, SUID files, cron and share directories. Prints which of smbd/nfsd/ftp/ssh are running. Later scripts diff against this baseline. | Writes only to `/root/hardening` |
| 02 | `02_backup_configs.sh` | Tarballs `/etc`, `/var/lib/samba`, `/var/lib/nfs` so you can roll back. | No |
| 03 | `03_change_passwords.sh` | Walks every login-capable account (and Samba users) and prompts for a new password. Reminds you about Quotient. | Passwords |
| 04 | `04_audit_users.sh` | **Read-only.** Lists extra UID-0 accounts, login shells, empty passwords, privileged groups, doas/sudo rules, every `authorized_keys` file. | No |
| 05 | `05_lock_user.sh user…` | Locks a suspicious account: password locked, shell → nologin, running processes killed. Reversible. Never locks root. | Accounts |
| 06 | `06_harden_ssh.sh` | Sets MaxAuthTries 3, no empty passwords, no forwarding/tunnels/X11, VERBOSE logging; optionally disables root login. Validates with `sshd -t` (auto-restores backup if invalid), reloads, prints effective values. Warns if drop-in files could override. Leaves PasswordAuthentication alone. | sshd_config |
| 07 | `07_firewall.sh` | Host iptables: default-deny INPUT, allow loopback, established, ping, and only ports currently listening. Logs drops as `FW-DROP` (shows scans). **90-second auto-rollback** unless you type `yes` from a working second session. Saves for boot. | iptables |
| 08 | `08_harden_samba.sh` | Global Samba settings: SMB2+ only, no anonymous/guest mapping, no null passwords, NTLMv2 only. Validates with `testparm`, offers restart, then lists shares that are guest/writable for you to review by hand. | smb.conf |
| 09 | `09_harden_nfs.sh` | Shows exports; offers `no_root_squash`→`root_squash` and replacing wildcard clients with a CIDR you enter; `exportfs -ra`. | /etc/exports |
| 10 | `10_harden_ftp.sh` | If vsftpd: disables anonymous login, enables transfer log. Warns about other FTP daemons. | vsftpd.conf |
| 11 | `11_review_services.sh` | Shows everything listening and enabled; flags telnet, rsh, tftp, VNC, cups, avahi, snmp, inetd and offers to stop/disable each. | Services (prompted) |
| 12 | `12_persistence_hunt.sh` | **Read-only.** Cron, startup hooks, inittab, `ld.so.preload`, recently changed init scripts, new SUID binaries vs baseline, executables in tmp dirs, hidden files in share dirs, recent `/etc` edits, shell history. | No |
| 13 | `13_fix_permissions.sh` | Resets modes on passwd/shadow/sshd_config/doas/sudoers/crontabs//root; reports world-writable, SUID and executable files inside share directories. | Permissions |
| 14 | `14_sysctl_harden.sh` | Drops `/etc/sysctl.d/99-hardening.conf`: no forwarding/redirects/source routing, SYN cookies, rp_filter, restricted dmesg/kptr, protected links. | sysctl |
| 15 | `15_logging_audit.sh` | Ensures syslog runs; optionally installs auditd with watches on passwd/shadow/doas/sshd/smb/exports/cron/root ssh, and optionally logs every command executed. | Packages/auditd |
| 16 | `16_integrity.sh init\|check` | `init` hashes system binaries and `/etc` (run **after** hardening). `check` shows changed/missing/new files and apk's own audit. Use it to detect red-team backdoors and trojaned binaries. | Writes baseline |
| 17 | `17_watch.sh [secs]` | **Live monitor** for a spare terminal/tmux. Alerts (red + logged to `logs/watch.log`) on new/closed listeners, new connections and source IPs, new processes, logged-in sessions, new/changed users, changed key files and `authorized_keys`, new files in share dirs, and ssh/samba/doas/firewall log lines. This is how you see what competitors/red team are doing. | No |
| 18 | `18_verify.sh` | **Read-only** final report: listeners, SSH settings, firewall, UID 0, empty passwords, smb.conf validity, service status. | No |

## Notes on watching activity
- `17_watch.sh` hides its own helper processes only; shells (`sh`, `ash`) spawned by others still show.
- For command-level visibility turn on the `execve` audit rule in script 15 (`ausearch -k exec -i`).
- Quick manual views: `who`, `last | head`, `tail -f /var/log/messages`, `ss -tnp`, `ps -ef`.
- `FW-DROP` lines in `/var/log/messages` show port scans and blocked attempts.

## Known limits
- Scripts assume stock Alpine: OpenRC, BusyBox, `apk`. Service names (`samba`, `sshd`, `vsftpd`, `iptables`) may differ; adjust if a restart errors.
- Script 07 can't tell which source IPs the scoring engine uses behind the 1:1 NAT, so it filters by port, not source.
- `apk add` (07, 15) needs repo access; if blocked, install packages another way or skip.
