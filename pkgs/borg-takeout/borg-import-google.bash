usage() {
    [[ "$#" -gt 0 ]] || printf 'error: %s\n' "$@" >&2
    cat >&2 <<EOF
usage: borg-import-google takeout-19700101T000000Z-*
EOF
    exit 69
}

[[ "$#" -ge 1 ]] || usage

files=()
for file; do
    files+=("@${file}")
done

archive_details=$(
    bsdtar -cf - --format=ustar "${files[@]}" \
        | bsdtar -Oxf - "Takeout/archive_browser.html"
)

[[ -n "${archive_details}" ]] || usage "invalid archive format; no 'Takeout/archive_browser.html' file found"

account=$(
    htmlq -t 'html > body .header_title' <<<"${archive_details}" \
        | grep -Eo '[^@[:space:]]+@[^@[:space:]]+'
)

date=$(
    htmlq -t 'html body .header_subtext' <<<"${archive_details}" \
        | sed 's/ / /g; s/ • .*//' \
        | dateconv -i '%b %-d, %Y, %-I:%M:%S %p %Z' -z UTC -f '%Y-%m-%dT%H:%M:%SZ'
)

printf '::google-%s-%s\n' "${account}" "${date}"

# shellcheck disable=SC2016
bsdtar -cf - --format=ustar "${files[@]}" \
    | borg \
        import-tar \
            --stats -p \
            --comment='imported with `borg import-tar`, via borg-import-google' \
            --timestamp="${date}" \
            "::google-${account}-${date}.failed" \
            -

borg \
    rename \
        "::google-${account}-${date}.failed" \
        "google-${account}-${date}"

borg \
    prune \
        --keep-monthly=12 --keep-yearly=4 \
        -a "google-${account}-*"
