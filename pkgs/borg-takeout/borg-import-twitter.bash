usage() {
    cat >&2 <<EOF
usage: borg-import-twitter twitter-1970-01-01-*
EOF
    exit 69
}

[[ "$#" -ge 1 ]] || usage

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
    | borg \
        import-tar \
            --stats -p \
            --comment='imported with `borg import-tar`, via borg-import-twitter' \
            --timestamp="${date}" \
            "::twitter-${account}-${date}.failed" \
            -

borg \
    rename \
        "::twitter-${account}-${date}.failed" \
        "twitter-${account}-${date}"

borg \
    prune \
        --keep-monthly=12 --keep-yearly=4 \
        -a "twitter-${accountid}-*"
