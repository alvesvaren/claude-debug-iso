# Claude Debug ISO

En Arch Linux-live-ISO som startar direkt i Claude Code, för snabb felsökning
av datorer.

## Flöde vid start

1. Bootar (3 s bootmeny) och loggar in som root automatiskt på tty1.
2. `claude-kiosk` startar en helskärmsterminal (`foot` i Wayland-kompositorn
   `cage`) med **svensk tangentbordslayout**. Om grafik inte går att starta körs
   samma flöde i textkonsolen (också med svensk layout, `sv-latin1`).
3. **Internet:** kabel ansluts automatiskt. Annars visas nätverksskärmen
   (`claude-net`), som uppdateras var 5:e sekund:
   - **Wi-Fi:** numrerad lista över nätverk. Tryck siffran och skriv lösenordet.
     `d` för dolt nätverk, `a` för `impala` (t.ex. företagsnät/802.1X).
   - **iPhone via USB:** känns igen och parkopplas automatiskt. Skärmen säger
     vad man ska göra: låsa upp, trycka "Lita på" och slå på Internetdelning.
   - **Android via USB:** slå på USB-internetdelning, så ansluts den direkt.

   Om systemklockan är fel (TLS-fel) ställs den från serverns Date-header.
   Nätverksskärmen går att nå senare med `w` i menyn efter Claude.
4. **Inloggning med QR-kod:** `claude-qr-login` kör `claude auth login` och
   visar inloggningslänken som QR-kod. Logga in i mobilen och skriv sedan in
   koden du får, eller skanna den andra QR-koden (om mobilen är på samma nätverk)
   för en sida där du loggar in och klistrar in koden direkt i mobilen.
5. **Claude Code** startar i `/root`, med en `CLAUDE.md` som beskriver
   livemiljön och en lista över tillåtna läskommandon (`lsblk`, `dmesg`,
   `journalctl`, `smartctl -a` …). När Claude avslutas visas en meny: starta igen,
   fortsätt senaste konversationen, skal, Wi-Fi, logga in på nytt, starta om
   eller stäng av.

## Bygga

Kräver Docker (bygget körs i en privilegierad `archlinux`-container):

```bash
./build.sh
```

ISO:n hamnar i `out/`. Claude Code laddas ner och bakas in vid bygget, så bygg
om för att få en nyare version.

### GitHub Actions

[`.github/workflows/build-iso.yml`](.github/workflows/build-iso.yml) bygger ISO:n
och publicerar den som en **release** (med `.sha256`):

- manuellt: Actions → *Bygg ISO* → *Run workflow*, eller `gh workflow run build-iso.yml`
- vid push av en tagg `v*` (sparas permanent)
- varje måndag, så att Claude Code-versionen hålls färsk. Bara de 3 senaste
  automatiska byggena (`build-*`) sparas.

Senaste ISO:n hämtas med:

```bash
gh release download --pattern '*.iso' --repo alvesvaren/claude-debug-iso
```

Skriv till USB (kontrollera enheten med `lsblk` först):

```bash
sudo dd if=out/claude-debug-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Testa i QEMU:

```bash
./run-vm.sh
```

## Struktur

| Sökväg | Innehåll |
| --- | --- |
| `build.sh` | Startar bygget i Docker |
| `scripts/build-in-container.sh` | Kopierar archisos `releng`-profil, lägger på overlay, hämtar Claude Code, kör `mkarchiso` |
| `overlay/packages.extra` | Paket utöver releng |
| `overlay/airootfs/usr/local/bin/claude-kiosk` | Startar cage + foot, eller textkonsolen som reserv |
| `overlay/airootfs/usr/local/bin/claude-session` | Huvudflödet: nätverk, inloggning, Claude, meny |
| `overlay/airootfs/usr/local/bin/claude-net` | Nätverksskärmen: Wi-Fi-lista, iPhone-parkoppling, status |
| `overlay/airootfs/usr/local/bin/claude-qr-login` | QR-inloggning och mobilsidan på LAN:et (port 8484) |
| `overlay/airootfs/root/CLAUDE.md` | Instruktioner till Claude om livemiljön |
| `overlay/airootfs/root/.claude/settings.json` | Tillåtna läskommandon |

## Kernelparametrar

Lägg till i bootmenyn (Tab eller `e`):

- `claude.notty`: hoppa över grafikläget och kör i textkonsolen.
- `claude.nokiosk`: starta inte kiosken alls, bara ett vanligt root-skal.

## Bra att veta

- Claude Code kräver en x86-64-processor med **AVX2** (Intel Haswell/2013,
  AMD Excavator/2015 eller senare). På äldre datorer visas ett meddelande om det
  och du får ett vanligt skal med felsökningsverktygen. I QEMU utan KVM behövs
  `-cpu Haswell-noTSX` eller nyare.
- Allt ligger i RAM: inloggningen och konversationerna försvinner vid omstart.
- Mobilsidan för inloggning skyddas av en slumpad token i länken och stängs så
  fort en kod har skickats.
- Textstorlek i foot: `Ctrl` + `+` eller `Ctrl` + `-`.
