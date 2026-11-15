#!/usr/bin/env bash
# Körs inuti en privilegierad archlinux-container av ../build.sh.
# Utgår från archisos officiella releng-profil och lägger på overlay/.
set -euo pipefail

SRC=/src
PROFILE=/tmp/profile
WORK=/tmp/work
OUT=$SRC/out

echo "==> Installerar archiso"
pacman -Syu --noconfirm --needed archiso curl >/dev/null

echo "==> Skapar profil från releng"
rm -rf "$PROFILE" "$WORK"
cp -r /usr/share/archiso/configs/releng "$PROFILE"
cp -rT "$SRC/overlay/airootfs" "$PROFILE/airootfs"
grep -Ev '^\s*(#|$)' "$SRC/overlay/packages.extra" >> "$PROFILE/packages.x86_64"

cat >> "$PROFILE/profiledef.sh" <<'EOF'

# --- Claude Debug ISO ---
iso_name="claude-debug"
iso_label="CLAUDE_DEBUG_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Claude Debug ISO"
iso_application="Claude Code live debug environment"
file_permissions+=(
  ["/usr/local/bin/claude"]="0:0:755"
  ["/usr/local/bin/claude-kiosk"]="0:0:755"
  ["/usr/local/bin/claude-session"]="0:0:755"
  ["/usr/local/bin/claude-qr-login"]="0:0:755"
  ["/usr/local/bin/claude-net"]="0:0:755"
  ["/usr/local/bin/claude-usb"]="0:0:755"
  ["/usr/local/bin/claude-headless"]="0:0:755"
  ["/opt/claude/claude"]="0:0:755"
  ["/root/.claude"]="0:0:700"
)
EOF

# Bootmenyer: eget namn, RAM-overlay på halva minnet (tmpfs tar bara det som
# faktiskt skrivs; standard är 256M, för lite för pacman -S under felsökning)
# och kortare väntetid.
sed -i -e 's/Arch Linux install medium/Claude Debug ISO/g' \
       -e 's/%KERNEL_PARAMS%/cow_spacesize=50% %KERNEL_PARAMS%/g' \
    "$PROFILE"/efiboot/loader/entries/*.conf "$PROFILE"/syslinux/*.cfg "$PROFILE"/grub/*.cfg
sed -i 's/^timeout .*/timeout 3/' "$PROFILE/efiboot/loader/loader.conf"
sed -i 's/^TIMEOUT .*/TIMEOUT 30/' "$PROFILE/syslinux/archiso_sys.cfg"
sed -i 's/^timeout=.*/timeout=3/' "$PROFILE"/grub/*.cfg

echo "==> Hämtar Claude Code"
export HOME=/tmp/claude-home
rm -rf "$HOME"
mkdir -p "$HOME"
curl -fsSL https://claude.ai/install.sh | bash >/dev/null
bin=$(readlink -f "$HOME/.local/bin/claude")
install -Dm755 "$bin" "$PROFILE/airootfs/opt/claude/claude"
claude_version=$("$bin" --version | awk '{print $1}')
echo "    Claude Code $claude_version"

echo "==> Bygger ISO"
mkdir -p "$OUT"
mkarchiso -v -r -w "$WORK" -o "$OUT" "$PROFILE"
# Används av GitHub Actions i releasetexten
echo "$claude_version" > "$OUT/claude-code-version.txt"

if [[ -n ${HOST_UID:-} ]]; then
    chown -R "$HOST_UID:$HOST_GID" "$OUT"
fi
ls -lh "$OUT"/*.iso
