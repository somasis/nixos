usage() {
    cat >&2 <<'EOF'
usage: borg-import-instagram username_YYYYMMDD.zip
EOF
    exit 69
}

[[ "$#" -ge 1 ]] || usage

account=$(basename "$1" .zip)
account=${account%_[0123456789][0123456789][0123456789][0123456789][0123456789][0123456789][0123456789][0123456789]}

temp=$(mktemp -d)
first_file=$(bsdtar -tf "$1" | grep -e '\.json$' -e '\.txt$' | head -n1) || [[ -n "${first_file}" ]]
bsdtar -C "${temp}" -xf "$(readlink -f "$1")" "${first_file}"
date=$(TZ=UTC stat -c '%Y' "${temp}"/"${first_file}")
date=$(dateconv -i "%s" -z UTC -f "%Y-%m-%dT%H:%M:%SZ" "${date}")
rm -r "${temp}"

printf '::instagram-%s-%s\n' "${account}" "${date}"

# shellcheck disable=SC2016
bsdtar -cf - --format=ustar @"$1" \
    | borg \
        import-tar \
            --stats -p \
            --comment='imported with `borg import-tar`, via borg-import-instagram' \
            --timestamp="${date}" \
            "::instagram-${account}-${date}.failed" \
            -

borg \
    rename \
        "::instagram-${account}-${date}.failed" \
        "instagram-${account}-${date}"

borg \
    prune \
        --keep-monthly=12 --keep-yearly=4 \
        -a "instagram-${account}-*"
