usage() {
    cat >&2 <<EOF
usage: borg-import-twitter twitter-1970-01-01-*
EOF
    exit 69
}

[[ "$#" -ge 1 ]] || usage

date=$(TZ=UTC date +%Y-%m-%dT%H:%M:%SZ)

files=()
for f; do
    files+=("@${f}")
done

a=$(
    bsdtar -cf - --format=ustar "${files[@]}" \
        | bsdtar -Ox -f - "data/account.js" \
        | sed '/\[$/d; /^\]$/d' \
        | jq -r '"\(.account.accountId)-\(.account.username)"'
)

aid=${a%-*}

d=${1##*/}
d=${d%.*}
d=${d%-*}
d=${d#twitter-}
d="${d}"T00:00:00

printf '::twitter-%s-%s (%s)\n' "${a}" "${date}" "${d}"

bsdtar -cf - --format=ustar "${files[@]}" \
    | borg \
        import-tar \
            "${extraArgs}" \
            --stats -p \
            --comment='imported with `borg import-tar`, via borg-import-twitter' \
            --timestamp="${d}" \
            "::twitter-${a}-${date}.failed" \
            -

borg \
    rename \
        "${extraArgs}" \
        "::twitter-${a}-${date}.failed" \
        "twitter-${a}-${date}"

borg \
    prune \
        "${extraArgs}" \
        --keep-monthly=12 --keep-yearly=4 \
        -a "twitter-${aid}-*"
