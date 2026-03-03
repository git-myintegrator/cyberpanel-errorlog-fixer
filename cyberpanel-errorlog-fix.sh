#!/bin/bash
# =============================================================================
#  CYBERPANEL ERROR LOG LEVEL FIXER
#
#  This script scans all CyberPanel/OpenLiteSpeed vhost.conf files and:
#    - Changes logLevel WARN to logLevel WARNING
#    - Fixes error log file permissions and ownership
#    - Restarts OpenLiteSpeed if changes were made
#
#  Author: Jesus Suarez (soporteserver)
# =============================================================================

VHOSTS_BASE="/usr/local/lsws/conf/vhosts"

for VHOST_DIR in "$VHOSTS_BASE"/*; do
    if [ -d "$VHOST_DIR" ]; then
        VHOST_CONF="$VHOST_DIR/vhost.conf"
        VH_NAME=$(basename "$VHOST_DIR")
        VH_LOG="/home/$VH_NAME/logs/${VH_NAME}.error_log"

        if [ -f "$VHOST_CONF" ]; then
            cp "$VHOST_CONF" "$VHOST_CONF.bak.$(date +%F-%H%M%S)"
            CHANGED=0
            if grep -iq "logLevel" "$VHOST_CONF"; then
                # Replace only logLevel lines where the level is exactly WARN/warn/Warning (not WARNING)
                sed -i '/logLevel[[:space:]]\+WARN$/i\' "$VHOST_CONF" && \
                    sed -i 's/logLevel[[:space:]]\+WARN$/logLevel                WARNING/i' "$VHOST_CONF" && CHANGED=1
                sed -i '/logLevel[[:space:]]\+warn$/i\' "$VHOST_CONF" && \
                    sed -i 's/logLevel[[:space:]]\+warn$/logLevel                WARNING/i' "$VHOST_CONF" && CHANGED=1
                sed -i '/logLevel[[:space:]]\+Warning$/i\' "$VHOST_CONF" && \
                    sed -i 's/logLevel[[:space:]]\+Warning$/logLevel                WARNING/i' "$VHOST_CONF" && CHANGED=1
                if grep -q "logLevel[[:space:]]\+WARNINGING" "$VHOST_CONF"; then
                    echo "[$VH_NAME] logLevel WARNINGING found and should be fixed in $VHOST_CONF"
                fi
                [ $CHANGED -eq 1 ] && echo "[$VH_NAME] logLevel set to WARNING in $VHOST_CONF"
            fi

            if [ -f "$VH_LOG" ]; then
                chmod 644 "$VH_LOG"
                chown nobody:nobody "$VH_LOG"
                echo "[$VH_NAME] Permissions and ownership fixed for $VH_LOG"
            else
                echo "[$VH_NAME] Log file $VH_LOG does not exist, skipping"
            fi

            LOG_DIR="/home/$VH_NAME/logs"
            if [ ! -d "$LOG_DIR" ]; then
                mkdir -p "$LOG_DIR"
                echo "[$VH_NAME] logs directory created at $LOG_DIR"
            fi
            chown root:nobody "$LOG_DIR"
            chmod 755 "$LOG_DIR"
            echo "[$VH_NAME] logs directory permissions and ownership fixed"
        fi
    fi
done

if pgrep litespeed >/dev/null; then
    systemctl restart lsws && echo "OpenLiteSpeed restarted."
else
    systemctl restart lscpd && echo "LSCPD restarted (CyberPanel panel)."
fi

echo "Script completed."
