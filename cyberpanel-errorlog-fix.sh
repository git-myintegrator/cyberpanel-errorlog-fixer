#!/bin/bash
# =============================================================================
#  CYBERPANEL ERROR LOG LEVEL FIXER
# =============================================================================

set -u

VHOSTS_BASE="/usr/local/lsws/conf/vhosts"
BACKUP_DIR="$HOME/backup/lsws_vhosts"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

for VHOST_DIR in "$VHOSTS_BASE"/*; do
    [ -d "$VHOST_DIR" ] || continue

    VHOST_CONF="$VHOST_DIR/vhost.conf"
    VH_NAME="$(basename "$VHOST_DIR")"
    VH_LOG="/home/$VH_NAME/logs/${VH_NAME}.error_log"
    LOG_DIR="/home/$VH_NAME/logs"

    [ -f "$VHOST_CONF" ] || continue

    # Backup before modification (only if change required)
    if grep -Eq '^[[:space:]]*logLevel[[:space:]]+(WARN|warn|Warning|WARNINGING)$' "$VHOST_CONF"; then
        BACKUP_FILE="$BACKUP_DIR/${VH_NAME}_vhost.conf.$(date +%F-%H%M%S)"
        cp "$VHOST_CONF" "$BACKUP_FILE"

        sed -i -E 's/^([[:space:]]*logLevel[[:space:]]+)(WARN|warn|Warning|WARNINGING)$/\1WARNING/' "$VHOST_CONF"

        echo "[$VH_NAME] logLevel normalized to WARNING (backup: $BACKUP_FILE)"
    fi

    # Ensure log directory exists
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
        echo "[$VH_NAME] logs directory created at $LOG_DIR"
    fi

    chown root:nobody "$LOG_DIR" 2>/dev/null
    chmod 755 "$LOG_DIR"
    echo "[$VH_NAME] logs directory ownership/permissions verified"

    # Fix log file permissions if present
    if [ -f "$VH_LOG" ]; then
        chmod 644 "$VH_LOG"
        chown nobody:nobody "$VH_LOG" 2>/dev/null
        echo "[$VH_NAME] log file ownership/permissions verified"
    else
        echo "[$VH_NAME] Log file $VH_LOG does not exist, skipping"
    fi
done

# Always restart OpenLiteSpeed
systemctl restart lsws && echo "OpenLiteSpeed restarted."

echo "Script completed."