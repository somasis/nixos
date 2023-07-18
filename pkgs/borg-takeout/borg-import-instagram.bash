usage() {
    cat >&2 <<EOF
usage: borg-import-instagram username_YYYYMMDD.zip (JSON format only)
EOF
    exit 69
}

[[ "$#" -ge 1 ]] || usage

if ! d=$(dateconv -i '_%Y%m%d.zip' -f %Y-%m-%dT%H:%M:%SZ <<<"$1"); then
    printf 'error: filename "%s" is unexpected format\n' "$1" >&2
    exit 1
fi

n=$(basename "$1")
n=${n%_[0123456789][0123456789][0123456789][0123456789][0123456789][0123456789][0123456789][0123456789]}

printf '::instagram-%s-%s\n' "${n}" "${d}"

bsdtar -cf - --format=ustar "$1" \
    | borg \
        import-tar \
            "${extraArgs}" \
            --stats -p \
            --comment='imported with `borg import-tar`, via borg-import-instagram' \
            "::instagram-${n}-${d}.failed" \
            -

borg \
    rename \
        "${extraArgs}" \
        "::instagram-${n}-${d}.failed" \
        "instagram-${n}-${d}"

borg \
    prune \
        "${extraArgs}" \
        --keep-monthly=12 --keep-yearly=4 \
        -a "instagram-${n}-*"
