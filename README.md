# Claude Debug ISO

En Arch Linux-live-ISO som startar direkt i Claude Code, för snabb felsökning
av datorer.

## Flöde vid start

1. Bootar (3 s bootmeny) och loggar in som root automatiskt på tty1.
2. `claude-kiosk` startar en helskärmsterminal (`foot` i Wayland-kompositorn
   `cage`) med **svensk tangentbordslayout**. Om grafik inte går att starta körs
   samma flöde i textkonsolen (också med svensk layout, `sv-latin1`).
3. **Internet:** kabel, och Wi-Fi som finns i `wifi.txt` på stickan, ansluts automatiskt. Annars visas nätverksskärmen
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

## USB-stickan: Wi-Fi, inloggning och körning utan skärm

Ligger ISO:n på en **Ventoy-sticka** används mappen `claude-debug/` på stickan
(skapas automatiskt första gången, och går att redigera i Windows):

| Fil | Vad |
| --- | --- |
| `wifi.txt` | Wi-Fi-nätverk, en rad per nätverk: `namn = lösenord`. Läses in vid start, så att datorn ansluter direkt. Nätverk som du ansluter till via nätverksskärmen läggs till automatiskt. |
| `claude-data.tgz` | Claude-inloggningen och de 20 senaste konversationerna. Sparas löpande (varje minut vid ändringar, när Claude avslutas och vid avstängning). Med `c` i menyn fortsätter du alltså även efter en omstart. Ta bort filen för att logga ut. |
| `prompt.txt` | **Körning utan skärm.** Om filen finns kör Claude uppgiften i den och stänger sedan av datorn. Har datorn en skärm kan man trycka på en tangent inom 10 sekunder för att få vanligt läge istället. |
| `resultat/` | `<datum>_<dator>.md` med Claudes svar och `…-logg.txt` med vad Claude gjorde. Medan körningen pågår står det i svarsfilen var den är eller fastnade, till exempel "Väntar på internet" eller "Inte inloggad". |

Så kör du utan skärm:

1. Starta ISO:n en gång med skärm och logga in med QR-koden. Inloggningen
   sparas på stickan.
2. Lägg till Wi-Fi i `wifi.txt`, om datorn inte har kabel.
3. Skriv uppgiften i `prompt.txt` (se `prompt-exempel.txt`).
4. Starta datorn från stickan och vänta tills den stänger av sig själv. Läs
   sedan svaret i `resultat/`.

Utan skärm kör Claude med fulla rättigheter (`--dangerously-skip-permissions`),
eftersom ingen kan godkänna kommandon. Den har dock instruktioner att inte
skriva till datorns diskar om inte uppgiften uttryckligen ber om det. Formulera
prompten därefter.

Utan Ventoy (ISO:n skriven med `dd`) går det att använda en annan USB-sticka
eller partition med etiketten `CLAUDE_DATA`.

> `wifi.txt` och `claude-data.tgz` ligger okrypterade på stickan. Den som har
> stickan kan läsa Wi-Fi-lösenorden och använda ditt Claude-konto.

Partitionen monteras bara medan något läses eller skrivs, så stickan kan dras
ut när som helst. Under Ventoy är partitionen upptagen (Ventoy använder den
för ISO-filen), och då monteras den via en egen device-mapper-mappning.

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
| `overlay/airootfs/usr/local/bin/claude-usb` | Hittar Ventoy-stickan: `wifi.txt`, sparad inloggning, `prompt.txt`, resultat |
| `overlay/airootfs/usr/local/bin/claude-headless` | Kör `prompt.txt` med `claude -p` och skriver svaret till stickan |
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
- Allt ligger i RAM, utom det som sparas på USB-stickan (se ovan). Rotfilsystemets
  overlay får använda upp till halva minnet (`cow_spacesize=50%`).
- Utöver releng finns bland annat chntpw/hivex/wimlib/7zip för Windows,
  stress-ng/memtester, fwupd och os-prober/sbctl/mokutil. Hela listan står i
  `overlay/packages.extra`.
- Mobilsidan för inloggning skyddas av en slumpad token i länken och stängs så
  fort en kod har skickats.
- Textstorlek i foot: `Ctrl` + `+` eller `Ctrl` + `-`.
