# fix for screen readers
if grep -Fqa 'accessibility=' /proc/cmdline &> /dev/null; then
    setopt SINGLE_LINE_ZLE
fi

~/.automated_script.sh

# Starta Claude-kiosken på tty1. Hoppas över med kernelparametern
# claude.nokiosk eller i skärmläsarläget.
if [[ $(tty) == /dev/tty1 && -z $CLAUDE_KIOSK_STARTED ]] \
    && ! grep -Eqa 'claude\.nokiosk|accessibility=' /proc/cmdline; then
    export CLAUDE_KIOSK_STARTED=1
    claude-kiosk
    print "\nKiosken avslutades. Kör 'claude-kiosk' för att starta den igen."
fi
