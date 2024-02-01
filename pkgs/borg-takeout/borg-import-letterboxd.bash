usage() {
    [[ "$#" -gt 0 ]] || printf 'error: %s\n' "$@" >&2
    cat >&2 <<EOF
usage: borg-import-letterboxd [borg arguments --] letterboxd-*.zip
EOF
    exit 69
}

borg_args=()
case "$1" in
    --) shift ;;
    -*)
        # Get list of args to pass to `borg`.
        until [[ "$1" == '--' ]]; do
            borg_args+=( "$1" )
        done
        shift
        ;;
esac

if [[ "$#" -lt 1 ]]; then
    usage 'no archives given'
fi

n=$(basename "$1" .zip)
n=${n#letterboxd-}

account=${n%-*-*-*-*-*-utc}

temp=$(mktemp -d)
first_file=$(bsdtar -tf "$1" | head -n1) || [[ -n "${first_file}" ]]
bsdtar -C "${temp}" -xf "$(readlink -f "$1")" "${first_file}"
date=$(TZ=UTC stat -c '%Y' "${temp}"/"${first_file}")
date=$(dateconv -i "%s" -z UTC -f "%Y-%m-%dT%H:%M:%SZ" "${date}")
rm -r "${temp}"

printf '::letterboxd-%s-%s\n' "${account}" "${date}"

# shellcheck disable=SC2016
bsdtar -cf - --format=ustar @"$1" \
    | borg "${borg_args[@]}" \
        import-tar \
            --stats -p \
            --comment='imported with `borg import-tar`, via borg-import-letterboxd' \
            --timestamp="${date}" \
            "::letterboxd-${account}-${date}.failed" \
            -

borg "${borg_args[@]}" \
    rename \
        "::letterboxd-${account}-${date}.failed" \
        "letterboxd-${account}-${date}"

borg "${borg_args[@]}" \
    prune \
        --keep-monthly=12 --keep-yearly=4 \
        -a "letterboxd-${account}-*"
