#!/usr/bin/env bash
# Testkör senaste ISO:n i QEMU (UEFI om OVMF finns, annars BIOS).
# Port 8484 vidarebefordras så att mobilsidan för inloggning går att nå via
# http://<den här datorns IP>:8484/... (byt IP:n i länken som visas).
set -euo pipefail
cd "$(dirname "$0")"

iso=$(ls -t out/*.iso | head -1)
args=(-m 4G -smp 4 -cdrom "$iso" -boot d
      -device virtio-net-pci,netdev=n0 -netdev user,id=n0,hostfwd=tcp::8484-:8484
      -device VGA,xres=1600,yres=900 -display "${DISPLAY_MODE:-gtk}")

# Claude Code kräver AVX2, som QEMU:s standard-CPU saknar
if [[ -e /dev/kvm ]]; then
    args+=(-enable-kvm -cpu host)
else
    args+=(-cpu Haswell-noTSX -accel tcg,thread=multi)
fi
ovmf=/usr/share/edk2/x64/OVMF.4m.fd
[[ -f $ovmf ]] && args+=(-bios "$ovmf")

exec qemu-system-x86_64 "${args[@]}" "$@"
