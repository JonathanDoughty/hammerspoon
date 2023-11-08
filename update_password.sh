#!/usr/bin/env bash
# Update password records in KeyChain

shopt -s extglob

GENERIC_SERVICES='pwmgr|ssh\ passphrase|bitwarden|1password|lastpass'

case "${1:-no service}" in
    (@($GENERIC_SERVICES))
        PWTYPE=generic
        SERVICE="$1"
    ;;
    (login)                     # i.e., login password for this host
        PWTYPE="internet"
        SERVICE="$(uname -n)"
        ;;
    (*)
        printf "%s not recognized in %s\n" "$1" "$GENERIC_SERVICES"
        exit
        ;;
esac

if security find-"$PWTYPE"-password -a "${USER}" -s "$SERVICE" -w 1>/dev/null 2>&1; then
    #security delete-"$PWTYPE"-password -a "${USER}" -s "$SERVICE" 1>/dev/null
    CHANGE="updated to"
else
    CHANGE="added as"
fi
# Prompt for and add requested password to Keychain
security add-"$PWTYPE"-password -U -a "${USER}" -s "$SERVICE" -w
printf "%s password for %s %s: %s\n" "$PWTYPE" "$SERVICE" "$CHANGE" \
       "$(security find-"$PWTYPE"-password -a "${USER}" -s "$SERVICE" -w)"
