#!/bin/sh

get() {
    if systemctl --user is-active -q sctd.service; then
        echo active
    else
        echo inactive
    fi
}

wait() {
    case "$(get)" in
        active) systemd-wait --user -q sctd.service inactive ;;
        inactive) systemd-wait --user -q sctd.service active ;;
    esac
}

printf 'SC%s\n' "$(get)"
while wait; do
    printf 'SC%s\n' "$(get)"
done
