#!/usr/bin/env bash
# Made by Zack Polson.

# Convert to freedom.
if [[ ! ${LANG} =~ "en_US" ]]; then
    export LANG="en_US.UTF-8"
    export LC_ALL="en_US.UTF-8"
    export LANGUAGE="en_US:en"
fi

# Setup Abernic functions? Not sure what they do tbh.
. /mnt/mod/ctrl/configs/functions &>/dev/null 2>&1
progdir="$(cd $(dirname "$0"); pwd)"

# Program vars.
LAUNCH_DIR="/mnt/mmc/Roms/APPS/quintessence"
STATIC_BIN="quintessence.arm64"
GAME_BIN="${LAUNCH_DIR}/${STATIC_BIN}"

# Cleanup log files.
function cleanup() {
    if [[ -d "${LAUNCH_DIR}/Quintessence" ]]; then
        rm ${LAUNCH_DIR}/Quintessence/*.log
        rmdir ${LAUNCH_DIR}/Quintessence
    fi
    rm -f ${LAUNCH_DIR}/log.txt
    rm -f ${LAUNCH_DIR}/debug.txt
    rm -f ${LAUNCH_DIR}/launch_log.txt
    sync
}

# Print some debug logs.
function debug() {
    cleanup
    export DEBUG_LOG="${LAUNCH_DIR}/debug.txt"
    echo "Logging debug info..."

    echo "\$DISPLAY: ${DISPLAY}" > ${DEBUG_LOG}
    echo "\$DISPLAY_ID: ${DISPLAY_ID}" >> ${DEBUG_LOG}
    echo "ARCH: $(arch)" >> ${DEBUG_LOG}
    echo "\$HW_MODEL: ${HW_MODEL}" >> ${DEBUG_LOG}
    echo "\$XDG_SESSION_TYPE: ${XDG_SESSION_TYPE}" >> ${DEBUG_LOG}
    echo "\$ESUDO: ${ESUDO}" >> ${DEBUG_LOG}

    cat ${DEBUG_LOG}
}

# Anbernics weird launcher.
function kill_dmenu {
    DMENU="/mnt/vendor/bin/dmenu.bin"

    killall dmenu.bin 2>/dev/null
    killall charg.dge 2>/dev/null
    killall ndsCtrl.dge 2>/dev/null
    killall vp.dge 2>/dev/null

    sleep 1
}

# Run through some checks for the enviroment.
function precheck() {
    if [[ ! -e ${GAME_BIN} ]]; then
        echo "ERROR: Binary not found."
        exit 1
    elif [[ "$XDG_SESSION_TYPE" == "tty" ]]; then
        echo "You're running in a terminal lil bro."
        exit 1
    elif [[ ! -x ${GAME_BIN} ]]; then
        chmod 0755 ${GAME_BIN}
    fi

    if [[ -z "$ESUDO" && "$PORTMASTER_ENABLED" = true ]]; then
        echo "\$ESUDO is empty, is PortMaster not setup?"
    fi

    if [[ -z "$DISPLAY_ID" ]]; then
        echo "ERROR: Could not find \$DISPLAY_ID."
    fi

    debug
}

# Loads a bunch of stuff I don't understand. Copied from what I saw other
# scripts were doing. Probably only compatible with my RG34XX for now.
function preload() {
    echo "Preloading libraries."
    # Portmaster setup.
    if [[ "$PORTMASTER_ENABLED" = true ]]; then
        export PORTMASTER="/roms/ports/PortMaster"
        CONTROL_TXT=${PORTMASTER}/control.txt
        if [[ -e ${CONTROL_TXT} ]]; then
            source "$CONTROL_TXT"
            get_controls
        fi
    fi

    # Setup display libraries.
    echo "Loading libraries."
    export LD_LIBRARY_PATH="/lib:/lib/aarch64-linux-gnu:$LD_LIBRARY_PATH"
    export DISPLAY_ID="$(cat /sys/class/power_supply/axp2202-battery/display_id)"
    precheck

    # These probably help. Idk I saw other scripts including these.
    SDL=/usr/lib/aarch64-linux-gnu/libSDL2-2.0.so.0.2800.5
    LIBFONTCFG=/usr/lib/aarch64-linux-gnu/libfontconfig.so.1.12.0
    if [[ $DISPLAY_ID == "1" ]]; then
        AUDIODEV=hw:2,0
    fi

    launch_game
}

function launch_game {
    # Finally we launch!
    echo "Launching ${STATIC_BIN}."
    PARAMS=--resolution "${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}" \
    -f \
    --rendering-driver "opengl3_es" \
    --audio-driver "ALSA"
    if [[ "$PORTMASTER_ENABLED" = true ]]; then
        ${ESUDO} ${GAME_BIN} >> ${DEBUG_LOG} 2>&1
    elif [[ -e "/usr/bin/startx" && "$XINIT_DIRECT" = true ]]; then
        kill_dmenu
        xinit ${GAME_BIN} ${PARAMS} >> ${DEBUG_LOG} 2>&1
    else
        LD_PRELOAD=${SDL}:${LIBFONTCFG} ${AUDIODEV} ${GAME_BIN} ${PARAMS} \
        >> ${DEBUG_LOG} 2>&1
    fi
}

# Lists the available commands and arguments.
print_help() {
    echo "  help:           This menu."
    echo "  clean, cleanup: Cleans up log files."
    echo "  -p:             Enables PortMaster. Disabled by default."
    echo "  -x:             Enables booting with xinit. Disabled by default."
}

# Handle launch arguments.
for ARG in $@; do
    if [[ $ARG == "help" ]]; then
        print_help
        exit 0
    elif [[ $ARG == "clean" || $ARG == "cleanup" ]]; then
        echo "Cleaning up log files..."
        cleanup
        exit 0
    elif [[ $ARG == "-p" ]]; then
        PORTMASTER_ENABLED=true
    elif [[ $ARG == "-x" ]]; then
        XINIT_DIRECT=true
    elif [[ -n $ARG && $ARG != ${GAME_BIN} ]]; then
        echo "Unknown argument: $1" > "${LAUNCH_DIR}/launch_log.txt" 2>&1
        sync
        exit 1
    fi
done

XINIT_DIRECT=true
preload
sync
exit 0
