usage() {
    [[ "$#" -gt 0 ]] || printf 'error: %s\n' "$@" >&2
    cat >&2 <<'EOF'
usage: borg-import-facebook [borg arguments --] facebook-*.zip
EOF
    exit 69
}

borg_args=()
case "$1" in
    --) shift ;;
    -*)
        # Get list of args to pass to `borg`.
        until [[ "$1" == '--' ]]; do
            borg_args+=("$1")
        done
        shift
        ;;
esac

if [[ "$#" -lt 1 ]]; then
    usage 'no archives given'
fi

account=$(bsdtar -Oxf "$1" personal_information/profile_information/profile_information.json)
account=$(jq -r .profile_v2.username <<<"${account}")

temp=$(mktemp -d)
date=$(bsdtar -tf "$1" personal_information/profile_information/profile_information.json)
date=$(grep -v '/$' <<<"${date}" | head -n1)

bsdtar -C "${temp}" -xf "$1" "${date}"
date=$(TZ=UTC stat -c '%Y' "${temp}"/"${date}")
date=$(dateconv -i "%s" -z UTC -f '%Y-%m-%dT%H:%M:%SZ' "${date}")
rm -r "${temp}"

printf '::facebook-%s-%s\n' "${account}" "${date}"

# shellcheck disable=SC2016
bsdtar -cf - --format=ustar @"$1" \
    | borg "${borg_args[@]}" \
        import-tar \
            --stats -p \
            --comment='imported with `borg import-tar`, via borg-import-facebook' \
            --timestamp="${date}" \
            "::facebook-${account}-${date}.failed" \
            -

borg "${borg_args[@]}" \
    rename \
        "::facebook-${account}-${date}.failed" \
        "facebook-${account}-${date}"

borg "${borg_args[@]}" \
    prune \
        --keep-monthly=12 --keep-yearly=4 \
        -a "facebook-${account}-*"
