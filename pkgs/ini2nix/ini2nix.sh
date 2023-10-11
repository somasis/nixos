# shellcheck shell=sh

usage() {
    [ "$#" -eq 0 ] || printf '%s\n' "$@" >&2
    cat <<'EOF'
usage: ini2nix [-d] [FILE]
       ... | ini2nix [-d]
EOF
    exit 69
}

format() {
    if [ -t 1 ]; then
        nixfmt -w 120
    else
        cat
    fi
}

lists_as_duplicate_keys=false
while getopts :d opt >/dev/null 2>&1; do
    case "${opt}" in
        d) lists_as_duplicate_keys=true ;;
        *) usage "unknown option -- ${OPTARG}" ;;
    esac
done

shift $((OPTIND - 1))

path=${1:-}

case "${path}" in
    - | '') path=/dev/stdin ;;
esac

jq=$(
    cat <<'EOF'
. as $original

    # If there's any non-object keys in the root of the main object,
    # then make a "globalSection" object. (and use the proper function)
    | ($original | map_values(select(type != "object")) | length > 0) as $hasGlobalKeys
    | if $hasGlobalKeys then
        [ (map_values(select(type != "object")) | paths) ] as $globalPaths
            | ($original | delpaths($globalPaths)) as $originalWithoutGlobal
            | { globalSection: (map_values(select(type != "object"))) } * $originalWithoutGlobal
    else
        $original
    end

    # Coerce numbers that are strings ("1") to numbers,
    # and booleans that are strings ("True"/"true") to booleans
    | (
        ..
            |= (
                select(type == "string")
                    |= (
                        if (test("[Tt]rue")) then
                            true
                        elif (test("[Ff]alse")) then
                            false
                        elif (test("^[0-9]+\\.[0-9]+$|^[0-9]+$")) then
                            tonumber
                        else
                            .
                        end
                    )
            )
    )

    # `jc --ini-dup` makes singular values into arrays unnecessarily,
    # and thus clashes with toINI. So, for any arrays with a length of 1,
    # make them not be arrays.
    | map_values(map_values(select(type == "array") | if length == 1 then .[] else . end))
EOF
)

json=$(
    jq \
        --argjson listsAsDuplicateKeys "${lists_as_duplicate_keys}" \
        -f <(printf '%s\n' "${jq}") \
        <<<"${ini}"
)

nix=$(printf '%s\n' "${json}" | json2nix)

function_args='{}'
if [ "${lists_as_duplicate_keys}" = 'true' ]; then
    ini=$(jc --ini-dup <"${path}")
    function_args='{ listsAsDuplicateKeys = true; }'
else
    ini=$(jc --ini <"${path}")
fi

function=lib.generators.toINI
if jq -e 'map_values(select(type != "object")) | length > 0' <<<"${ini}" >/dev/null; then
    function=lib.generators.toINIWithGlobalSection
fi

format <<EOF
${function} ${function_args} ${nix}
EOF
