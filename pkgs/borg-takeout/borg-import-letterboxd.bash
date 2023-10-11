usage() {
    cat >&2 <<EOF
usage: borg-import-letterboxd letterboxd-*.zip
EOF
    exit 69
}

[[ "$#" -ge 1 ]] || usage

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
    | borg \
        import-tar \
            --stats -p \
            --comment='imported with `borg import-tar`, via borg-import-letterboxd' \
            --timestamp="${date}" \
            "::letterboxd-${account}-${date}.failed" \
            -

borg \
    rename \
        "::letterboxd-${account}-${date}.failed" \
        "letterboxd-${account}-${date}"

borg \
    prune \
        --keep-monthly=12 --keep-yearly=4 \
        -a "letterboxd-${account}-*"
