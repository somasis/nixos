# shellcheck shell=bash disable=SC2016

usage() {
    # shellcheck disable=SC2059
    [[ "$#" -eq 0 ]] || printf "$@" >&2

    cat >&2 <<'EOF'
Convert INI-style input to Nix language declarations, generally suitable
for use with nixpkgs' INI file generation functions.

Conversion is done by transforming the INI into JSON with `jc`'s INI
parser, and then by using `json2nix` to turn the JSON into a Nix
attribute set.

Unlike `jc --ini-dup`, non-duplicated keys with only one value set will
not be made into lists.

Output will be formatted with `nixfmt` if standard output is a terminal.

usage: ini2nix [-CFdr] <file>
       ini2nix [-CFdr] [-]

options:
  -C            Do not coerce any values in the input.
                Usually, ini2nix will coerce boolean-like strings (such
                as "true"/"false", case-insensitive), and numbers (such
                as integers, floating points, scientific notation).
  -F            Do not print an intuited INI generator function, nor any
                arguments for it. Only print the attribute set.
  -d            Interpret repeated keys as lists.
  -r            Interpret quotes at start and end of values literally.
EOF

    [[ "$#" -eq 0 ]] || exit 1
    exit 69
}

# shellcheck disable=SC2120
prepare_for_json2nix() {
    # shellcheck disable=SC2016
    local jq_script='
. as $original
    # If there are any non-object keys in the root of the main object,
    # then make a "globalSection" object. (and use the proper function)
    | ($original | map_values(select(type != "object")) | length > 0) as $hasGlobalKeys
    | if $hasGlobalKeys then
        [ (map_values(select(type != "object")) | paths) ] as $globalPaths
            | ($original | delpaths($globalPaths)) as $originalWithoutGlobal
            | { globalSection: (map_values(select(type != "object"))) } * $originalWithoutGlobal
    end

    # Coerce numbers that are strings ("1") to numbers,
    # and booleans that are strings ("True"/"true") to booleans
    | if $coerceValues then
        ..
            |= (
                select(type == "string")
                    |= (
                        if (test("[Tt]rue")) then
                            true
                        elif (test("[Ff]alse")) then
                            false
                        elif (try (tonumber | true) catch (false)) then
                            tonumber
                        else
                            .
                        end
                    )
            )
    end

    # `jc --ini-dup` makes singular values into arrays unnecessarily,
    # and thus clashes with what toINI expects. So, for any arrays
    # with a length of 1, make them into singletons.
    | if $listsAsDuplicateKeys then
        map_values(map_values(
            select(type == "array")
                | if length == 1 then .[] end
        ))
    end
'

    jq \
        --argjson coerceValues "${coerce_values}" \
        --argjson listsAsDuplicateKeys "${lists_as_duplicate_keys}" \
        -f <(printf '%s' "${jq_script}")
}

format() {
    if [[ -t 1 ]]; then
        nixfmt -w 120
    else
        cat
    fi
}

coerce_values=true
lists_as_duplicate_keys=false
print_nixpkgs_function=true
quotes_are_literal=false
while getopts :CFdr opt >/dev/null 2>&1; do
    case "${opt}" in
        C) coerce_values=false ;;
        F) print_nixpkgs_function=false ;;
        d) lists_as_duplicate_keys=true ;;
        r) quotes_are_literal=true ;;
        *) usage 'unknown option -- %s\n' "${OPTARG@Q}" ;;
    esac
done
shift $((OPTIND - 1))

[[ "$#" -gt 0 ]] || set -- -

for path; do
    jc_args=()
    jc_error=0

    case "${path}" in
        -) path=/dev/stdin ;;
    esac

    nixpkgs_function_args='{}'
    if [[ "${lists_as_duplicate_keys}" == false ]]; then
        jc_args+=(--ini)
    else
        nixpkgs_function_args='{ listsAsDuplicateKeys = true; }'
        jc_args+=(--ini-dup)
    fi

    if [[ "${quotes_are_literal}" == true ]]; then
        jc_args+=(--raw)
    fi

    ini_as_json=$(jc "${jc_args[@]}" <"${path}") || jc_error=$?

    if [[ "${jc_error}" -ne 0 ]]; then
        # shellcheck disable=SC2016
        usage 'error: `jc` failed while converting %s to JSON (error code: %i)\n' \
            "${path@Q}" \
            "${jc_error}"
    fi

    ini_as_json=$(prepare_for_json2nix <<<"${ini_as_json}")

    json_as_nix=$(json2nix <<<"${ini_as_json}")

    output="${json_as_nix}"
    if [[ "${print_nixpkgs_function}" == true ]]; then
        nixpkgs_function='lib.generators.toINI'

        # Check if the ini has a global section (keys without a section header preceding them).
        if jq -e 'map_values(select(type != "object")) | length > 0' <<<"${ini_as_json}" >/dev/null; then
            nixpkgs_function='lib.generators.toINIWithGlobalSection'
        fi

        output="${nixpkgs_function} ${nixpkgs_function_args} ${output}"
    fi

    format <<<"${output}"
done
