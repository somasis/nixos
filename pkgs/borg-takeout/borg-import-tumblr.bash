usage() {
    cat >&2 <<EOF
usage: borg-import-tumblr *.zip
EOF
    exit 69
}

[[ "$#" -ge 1 ]] || usage

date=$(TZ=UTC date +%Y-%m-%dT%H:%M:%SZ)

files=()
for f; do
    files+=("@${f}")
done

t=$(mktemp -d)

bsdtar -cf - --format=ustar "${files[@]}" \
    | bsdtar -C "${t}" -x -f - "payload-0.json"

a=$(
    jq -r '.[0].data.email' <"${t}"/payload-0.json
)

d=$(
    TZ=UTC date \
        --date="@$(TZ=UTC stat -c %Y "${t}"/payload-0.json)" \
        +%Y-%m-%dT%H:%M:%SZ
)

rm -r "${t}"

printf '::tumblr-%s-%s (%s)\n' "${a}" "${date}" "${d}"

# shellcheck disable=SC2016
bsdtar -cf - --format=ustar "${files[@]}" \
    | borg \
        import-tar \
            --stats -p \
            --comment='imported with `borg import-tar`, via borg-import-tumblr' \
            --timestamp="${d}" \
            "::tumblr-${a}-${date}.failed" \
            -

borg \
    rename \
        "::tumblr-${a}-${date}.failed" \
        "tumblr-${a}-${date}"

borg \
    prune \
        --keep-monthly=12 --keep-yearly=4 \
        -a "tumblr-${a}-*"
