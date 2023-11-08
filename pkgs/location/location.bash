# shellcheck shell=bash

usage() {
    # shellcheck disable=SC2059
    [[ "$#" -eq 0 ]] || printf "$@" >&2

    cat >&2 <<EOF
usage: location [-Rr] [-M retries] [-a accuracy] [-c dd|dd-nesw] [-f format:prefix] [-m geoclue|mozilla] [-t timeout]
EOF
    exit 69
}

fetch_location() {
    local key value

    local method
    local attempted_methods=()

    local location=
    local location_found=false

    until [[ "${location_found}" == true ]]; do
        for method in "${requested_method}" geoclue mozilla; do
            case " ${attempted_methods[*]} " in
                *" ${method} "*) continue ;;
            esac

            case "${method}" in
                geoclue)
                    # Returns coordinates in decimal degrees (dd).
                    location=$(
                        while IFS=': ' read -r key value; do
                            key=${key,,}
                            key=${key// /_}

                            case "${key}" in
                                'latitude' | 'longitude' | 'accuracy')
                                    printf '%s=%q\n' "${key}" "${value}"
                                    ;;
                                'timestamp') break ;;
                            esac
                        done \
                            < <(
                                LC_ALL=C where-am-i \
                                    ${requested_accuracy:+-a "${requested_accuracy}"} \
                                    ${timeout:+-t "${timeout}"}
                            )
                    )

                    # .[:-1] is used to remove the degree sign at the end.
                    eval "${location}"
                    location_found=true

                    latitude=${latitude%%[?°]*}
                    longitude=${longitude%%[?°]*}
                    ;;
                mozilla)
                    # Returns coordinates in decimal degrees (dd).
                    location=$(
                        curl -Lfs \
                            ${timeout:+--max-time "${timeout}"} \
                            ${max_retries:+--retry "${max_retries}"} \
                            "https://location.services.mozilla.com/v1/geolocate?key=geoclue"
                    )

                    location=$(
                        jq -r '
                            "latitude=\(.location.lat | @sh)",
                            "longitude=\(.location.lng | @sh)",
                            "accuracy=\(.accuracy | @sh)"
                        ' <<<"${location}"
                    )

                    eval "${location}"
                    location_found=true
                    ;;
                *)
                    usage 'error: invalid location method: "%s"\n' "${method}"
                    ;;
            esac

            attempted_methods+=("${method}")
            if [[ "${location_found}" == true ]]; then
                break
            fi
        done

        if [[ "${retry}" == false ]]; then
            break
        fi
    done

    if [[ "${location_found}" == false ]]; then
        if [[ "${retry}" == false ]]; then
            printf 'error: no location could be retrieved, and retrying was not permitted\n' >&2
        else
            printf 'error: no location could be retrieved\n' >&2
        fi
        exit 1
    fi
}

requested_accuracy=6
coordinate_format='dd'
output_format='default'
requested_method=
resolve=false
retry=false
max_retries=5
timeout=
while getopts :RrM:a:c:f:m:t: opt >/dev/null 2>&1; do
    case "${opt}" in
        R) retry=true ;;
        M) max_retries="${OPTARG}" ;;
        r) resolve=true ;;
        a) requested_accuracy="${OPTARG}" ;;
        c) coordinate_format="${OPTARG}" ;;
        f) output_format="${OPTARG}" ;;
        m) requested_method="${OPTARG}" ;;
        t) timeout="${OPTARG}" ;;
        :) usage "error: option '%s' requires argument\n" "${OPTARG}" ;;
        *) usage "error: unknown option -- '%s'\n" "${opt}" ;;
    esac
done
shift $((OPTIND - 1))

# GeoClue and Nominatim have different accuracy schemes.
# GeoClue: "Country = 1, City = 4, Neighborhood = 5, Street = 6, Exact = 8"
# Nomiantim: <https://nominatim.org/release-docs/develop/api/Reverse/#result-restriction>
case "${requested_accuracy}" in
    1) requested_accuracy_nominatim=3 ;;  # country      == "country"
    4) requested_accuracy_nominatim=10 ;; # city         == "city"
    5) requested_accuracy_nominatim=14 ;; # neighborhood == "neighborhood"
    6) requested_accuracy_nominatim=17 ;; # street       ~= "major and minor streets"
    8) requested_accuracy_nominatim=18 ;; # exact        ~= "building"
    *)
        usage 'error: invalid requested accuracy: %s\n' "${requested_accuracy}"
        ;;
esac

fetch_location

if [[ "${resolve}" == true ]]; then
    resolved=$(
        curl -Lfs \
            ${timeout:+--max-time "${timeout}"} \
            ${LC_ADDRESS:+-A "Accept-Language: ${LC_ADDRESS}"} \
            -G \
            -d format=json \
            -d lat="${latitude}" \
            -d lon="${longitude}" \
            -d layer=address \
            ${requested_accuracy:+-d zoom="${requested_accuracy_nominatim}"} \
            'https://nominatim.openstreetmap.org/reverse'
    )

    if [[ -n "${resolved}" ]]; then
        address=$(jq -r '.display_name' <<<"${resolved}")
    else
        printf 'error: location could not be resolved\n' >&2
        exit 1
    fi
fi

case "${coordinate_format}" in
    dd) : ;;
    dd-nesw)
        case "${latitude}" in
            -*) latitude="${latitude#-}S" ;;
            *) latitude="${latitude}N" ;;
        esac

        case "${longitude}" in
            -*) longitude="${longitude#-}W" ;;
            *) longitude="${longitude}E" ;;
        esac
        ;;
    *)
        usage 'error: invalid coordinate format: "%s"\n' "${coordinate_format}"
        ;;
esac

accuracy=${accuracy:-}

case "${output_format}" in
    shell | 'shell:'*)
        shell_variable_prefix=
        [[ "${output_format}" = 'shell' ]] || shell_variable_prefix=${output_format#shell:}

        printf '%s=%q\n' \
            "${shell_variable_prefix}latitude" "${latitude}" \
            "${shell_variable_prefix}longitude" "${longitude}"

        if [[ "${resolve}" == true ]]; then
            printf '%s=%q\n' \
                "${shell_variable_prefix}accuracy" "${accuracy}" \
                "${shell_variable_prefix}address" "${address}"
        fi
        ;;
    default)
        if [[ "${resolve}" == true ]]; then
            printf '%s\t%s\t%s\t%s\n' \
                "${latitude}" \
                "${longitude}" \
                "${accuracy}" \
                "${address}"
        else
            printf '%s\t%s\n' \
                "${latitude}" \
                "${longitude}"
        fi
        ;;
    *)
        usage 'error: invalid output format: "%s"\n' "${output_format}"
        ;;
esac
