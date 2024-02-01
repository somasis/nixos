usage() {
    [[ "$#" -gt 0 ]] || printf 'error: %s\n' "$@" >&2
    cat >&2 <<EOF
usage: borg-import-twitter [borg arguments --] twitter-1970-01-01-*
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

files=()
for file; do
    files+=("@${file}")
done

account=$(
    bsdtar -cf - --format=ustar "${files[@]}" \
        | bsdtar -Ox -f - "data/account.js" \
        | sed '/\[$/d; /^\]$/d' \
        | jq -r '"\(.account.accountId)-\(.account.username)"'
)

accountid=${account%%-*}

date=${1##*/}
date=${date%.*}
date=${date%-*}
date=${date#twitter-}
date="${date}"T00:00:00

printf '::twitter-%s-%s\n' "${account}" "${date}"

# shellcheck disable=SC2016
bsdtar -cf - --format=ustar "${files[@]}" \
    | borg "${borg_args[@}" \
        import-tar \
            --stats -p \
            --comment='imported with `borg import-tar`, via borg-import-twitter' \
            --timestamp="${date}" \
            "::twitter-${account}-${date}.failed" \
            -

borg "${borg_args[@}" \
    rename \
        "::twitter-${account}-${date}.failed" \
        "twitter-${account}-${date}"

borg "${borg_args[@]}" \
    prune \
        --keep-monthly=12 --keep-yearly=4 \
        -a "twitter-${accountid}-*"
