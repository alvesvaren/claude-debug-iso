# Miljö: Claude Debug ISO

Du kör som **root** i en Arch Linux-livemiljö (archiso) som bootats från USB för
att felsöka just den här datorn eller något i dess nätverk. Användaren pratar
oftast svenska.

## Att veta om miljön

- Rotfilsystemet är ett overlay i RAM (`cow_spacesize=50%`, halva minnet). Allt
  försvinner vid omstart. Skriv stora filer (diskavbilder, backuper) till en
  extern disk, inte till `/` (`df -h /`).
- Inga diskar monteras automatiskt. Kartlägg först med `lsblk -f`.
- Pacmans databaser är inte synkade i avbilden. Behöver du verktyg som saknas:
  `pacman -Sy <paket>` (paketcachen ligger i RAM).
- Nätverk: systemd-networkd + iwd (`iwctl`, eller TUI:n `impala`), systemd-resolved.
- USB-stickan som ISO:n startades från (Ventoy) har mappen `claude-debug/`, där
  inloggning, Wi-Fi (`wifi.txt`) och resultat sparas. Den monteras bara
  tillfälligt. Vill användaren spara något på stickan:
  `claude-usb put resultat/<namn> < fil` (sökvägen är relativ till `claude-debug/`).
  Rör inte ISO-filerna eller resten av stickan.
- Finns redan:
  - Diskar: smartctl, nvme, hdparm, ddrescue, partclone, fsarchiver, testdisk/photorec,
    cryptsetup, lvm2, mdadm, btrfs/xfs/ntfs/exfat/f2fs-verktyg.
  - Boot: arch-chroot, efibootmgr, os-prober, sbctl, mokutil, fwupd.
  - Windows: chntpw (lösenord/register offline), hivex (`hivexregedit`, `hivexsh`),
    wimlib (`wimlib-imagex`), 7zip (`7z`). BitLocker låses upp med
    `cryptsetup open --type bitlk /dev/sdXN namn` (återställningsnyckel eller lösenord).
  - Hårdvara: lshw, dmidecode, inxi, sensors, upower, stress-ng, memtester.
    memtest86+ finns som eget val i bootmenyn.
  - Övrigt: nmap, tcpdump, mtr, iperf3, strace, lsof, git, jq, ripgrep.

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
