usage() {
    cat >&2 <<EOF
usage: borg-import-letterboxd letterboxd-*.zip
EOF
    exit 69
}

[[ "$#" -ge 1 ]] || usage

n=$(basename "$1")
n=${n#letterboxd-}

a=${n%-*-*-*-*-*-utc.zip}

d=${n#*-}
d=${d%-*.zip}
d=${d:0:10}T${d:11:2}:${d:14:2}:00Z

printf '::letterboxd-%s-%s\n' "${a}" "${d}"

bsdtar -cf - --format=ustar "$1" \
    | borg \
        import-tar \
            "${extraArgs}" \
            --stats -p \
            --comment='imported with `borg import-tar`, via borg-import-letterboxd' \
            "::letterboxd-${a}-${d}.failed" \
            -

borg \
    rename \
        "${extraArgs}" \
        "::letterboxd-${a}-${d}.failed" \
        "letterboxd-${a}-${d}"

borg \
    prune \
        "${extraArgs}" \
        --keep-monthly=12 --keep-yearly=4 \
        -a "letterboxd-${a}-*"
