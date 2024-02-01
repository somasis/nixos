usage() {
    [[ "$#" -gt 0 ]] || printf 'error: %s\n' "$@" >&2
    cat >&2 <<EOF
usage: borg-import-tumblr [borg arguments --] *.zip
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

date=$(TZ=UTC date +%Y-%m-%dT%H:%M:%SZ)

files=()
for file; do
    files+=("@${file}")
done

temp=$(mktemp -d)

bsdtar -cf - --format=ustar "${files[@]}" \
    | bsdtar -C "${temp}" -xf - "payload-0.json"

account=$(
    jq -r '.[0].data.email' <"${temp}"/payload-0.json
)

date=$(TZ=UTC stat -c %Y "${temp}"/payload-0.json)
date=$(dateconv -i '%s' -z UTC -f '%Y-%m-%dT%H:%M:%SZ' "${date}")

rm -r "${temp}"

printf '::tumblr-%s-%s\n' "${account}" "${date}"

# shellcheck disable=SC2016
bsdtar -cf - --format=ustar "${files[@]}" \
    | borg "${borg_args[@}" \
        import-tar \
            --stats -p \
            --comment='imported with `borg import-tar`, via borg-import-tumblr' \
            --timestamp="${date}" \
            "::tumblr-${account}-${date}.failed" \
            -

borg "${borg_args[@}" \
    rename \
        "::tumblr-${account}-${date}.failed" \
        "tumblr-${account}-${date}"

borg "${borg_args[@}" \
    prune \
        --keep-monthly=12 --keep-yearly=4 \
        -a "tumblr-${account}-*"
