# Miljö: Claude Debug ISO

Du kör som **root** i en Arch Linux-livemiljö (archiso) som bootats från USB för
att felsöka just den här datorn eller något i dess nätverk. Användaren pratar
oftast svenska.

## Att veta om miljön

- Rotfilsystemet är ett overlay i RAM (`cow_spacesize=2G`). Allt försvinner vid
  omstart, och stora installationer kan fylla det (`df -h /`).
- Inga diskar monteras automatiskt. Kartlägg först med `lsblk -f`.
- Behöver du verktyg som saknas: `pacman -Sy <paket>` (paketcachen ligger i RAM).
- Nätverk: systemd-networkd + iwd (`iwctl`, eller TUI:n `impala`), systemd-resolved.
- Finns redan: smartctl, nvme, testdisk/photorec, ddrescue, arch-chroot,
  cryptsetup, lvm2, mdadm, btrfs/xfs/ntfs/exfat-verktyg, efibootmgr, nmap,
  tcpdump, mtr, iperf3, strace, lsof, lshw, dmidecode, git, jq, ripgrep.

## Arbetssätt

- Börja läsande: samla fakta (loggar, `dmesg`, SMART, partitionstabeller) innan
  du föreslår åtgärder.
- Montera det installerade systemets diskar **read-only** först
  (`mount -o ro`). Montera skrivbart eller kör `arch-chroot` först när en
  ändring faktiskt behövs.
- Journal från det installerade systemet: `journalctl -D /mnt/var/log/journal`.
- **Fråga alltid** innan du kör något som skriver till en disk (`dd`, `mkfs`,
  `wipefs`, `fdisk`/`sgdisk`, `fsck` utan `-n`, `cryptsetup luksFormat`,
  `btrfs check --repair`, ändringar med `efibootmgr`). Säg exakt vilken enhet
  det gäller.
- Misstänker du en döende disk: kopiera med `ddrescue` först, reparera sedan
  kopian.
