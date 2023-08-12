usage() {
    cat >&2 <<EOF
usage: borg-import-google takeout-19700101T000000Z-*
EOF
    exit 69
}

[[ "$#" -ge 1 ]] || usage

date=$(TZ=UTC date +%Y-%m-%dT%H:%M:%SZ)

d=${1##*/}
d=${d%.tgz}
d=${d#takeout-}
d=${d%-*}
d=${d%Z}
d="${d:0:4}"-"${d:4:2}"-"${d:6:2}"T"${d:9:2}":"${d:11:2}":"${d:13:2}"

files=()
for f; do
    files+=("@${f}")
done

a=$(
    bsdtar -cf - --format=ustar "${files[@]}" \
        | bsdtar -Oxf - "Takeout/archive_browser.html" \
        | htmlq -t 'html > body h1.header_title' \
        | tr ' ' '\n' \
        | grep '@' \
        | head -n1
)

printf '::google-%s-%s (%s)\n' "${a}" "${date}" "${d}"

# shellcheck disable=SC2016
bsdtar -cf - --format=ustar "${files[@]}" \
    | borg \
        import-tar \
            --stats -p \
            --comment='imported with `borg import-tar`, via borg-import-google' \
            --timestamp="${d}" \
            "::google-${a}-${date}.failed" \
            -

borg \
    rename \
        "::google-${a}-${date}.failed" \
        "google-${a}-${date}"

borg \
    prune \
        --keep-monthly=12 --keep-yearly=4 \
        -a "google-${a}-*"
