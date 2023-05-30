# shellcheck shell=bash disable=SC3000-SC3999

set -euo pipefail

usage() {
    cat >&2 <<EOF
usage: qutebrowser-sync [-v] [-j jobs] [-d name]
       qutebrowser-sync [-v] [-j jobs] [-d name] -M
       qutebrowser-sync [-v] [-j jobs] [-d name] -T
       qutebrowser-sync [-v] [-d name] -l username password
       qutebrowser-sync [-v] -i value
EOF
    exit 69
}

log() {
    local level
    level="$1"
    shift

    [[ "${QUTEBROWSER_SYNC_VERBOSITY}" -gt "${level}" ]] && printf '%s\n' "$@" >&2
    return
}

edo() {
    local e

    [[ "${QUTEBROWSER_SYNC_VERBOSITY}" -ge 4 ]] && PS4="+ " && set -x >/dev/null
    # [[ "${QUTEBROWSER_SYNC_VERBOSITY}" -ge 4 ]] && echo "+ $*" >&2
    "$@"
    {
        e=$?
        set +x
    } 2>/dev/null
    return "${e}"

    # return "$?"
}

ldo() {
    local level
    level="$1"
    shift

    if [[ "${QUTEBROWSER_SYNC_VERBOSITY}" -ge "${level}" ]]; then
        edo "$@"
    else
        "$@"
    fi
}

dry() {
    if [[ "${QUTEBROWSER_SYNC_DRY_RUN}" == 'true' ]]; then
        printf '+ %s\n' "$*" >&2
    else
        edo "$@"
    fi
}

xe() {
    edo command xe -j "${QUTEBROWSER_SYNC_JOBS}" -F "$@"
}

ffsclient() {
    edo command ffsclient "$@" --sessionfile="${QUTEBROWSER_SYNC_SESSION}" --timezone=UTC
}

jq() { edo command jq -c "$@"; }
yq() { edo command yq -c "$@"; }

generate_id() {
    local x
    for x; do
        x=$(printf '%s' "${x}" | base64 -w0)
        x=${x%%=*}
        if [[ "${#x}" -lt 12 ]]; then
            x=$(printf '%-12s' "${x}")
            x=${x// /_}
        elif [[ "${#x}" -gt 12 ]]; then
            x=${x:$((${#x} - 12)):12}
        fi
        printf '%s\n' "${x}"
    done
}

# SC2016: Don't warn about expressions in single quotes, they're used by `xe`.
# SC2317: Don't warn about "unreachable commands".
# shellcheck disable=SC2016,SC2317
sync_marks() {
    log 1 "${QUTEBROWSER_SYNC_DEVICE}: synchronizing {book,quick}marks..."

    # Used for having a modification date of local bookmarks.
    local bm_modified_unix qm_modified_unix modified_unix
    local remote_records bm_local_records qm_local_records push_records pull_records

    bm_modified_unix=$(TZ=UTC stat -c %Y "${QUTEBROWSER_BOOKMARKS}")
    qm_modified_unix=$(TZ=UTC stat -c %Y "${QUTEBROWSER_QUICKMARKS}")
    modified_unix=$(
        if [[ "${bm_modified_unix}" -gt "${qm_modified_unix}" ]]; then
            echo "${bm_modified_unix}"
        else
            echo "${qm_modified_unix}"
        fi
    )

    remote_records=$(
        ffsclient list bookmarks --decoded --format json \
            | jq 'map(
              try .data |= fromjson
                | select(.data.deleted != true)
                | select(.data.type == "bookmark")
            )'
    )

    log 2 "${QUTEBROWSER_SYNC_DEVICE}: got remote bookmark records"
    log 4 "${QUTEBROWSER_SYNC_DEVICE}: $(jq <<<"${remote_records}")"

    bm_local_records=$(
        sed 's/ /\t/' "${QUTEBROWSER_BOOKMARKS}" \
            | nl -b a -d '' -f n -w 1 \
            | xe -LL -s '
                set -eu
                IFS=$(printf "\t")

                for mark; do
                    read -r id uri title <<< "$mark"
                    id=$("$QUTEBROWSER_SYNC" -i "${id}00")

                    printf "%s\t%s\t%s\n" "${id}" "${uri}" "${title}"
                done
            ' \
            | sort -snk1 \
            | cut -d' ' -f2- \
            | teip -d $'\t' -f1,2,3 -- jq -Rr '@json' \
            | tr '\t' '\n' \
            | xe -N0 -L printf '[ %s, %s, %s ]\n' \
            | jq -s \
                --argjson modified_unix "${bm_modified_unix}" '
                map({
                    data: {
                      parentid: "menu",
                      parentName: "menu",
                      id: .[0],
                      type: "bookmark",
                      title: .[2],
                      bmkUri: .[1],
                    },
                    id: .[0],
                    modified_unix: $modified_unix
                  }
                )
            '
    )
    log 2 "${QUTEBROWSER_SYNC_DEVICE}: got local bookmarks records"
    log 4 "${QUTEBROWSER_SYNC_DEVICE}: $(jq <<<"${bm_local_records}")"

    qm_local_records=$(
        sed -E 's/(^.+) (\S+)/\2\t\1/' "${QUTEBROWSER_QUICKMARKS}" \
            | nl -b a -d '' -f n -w 1 \
            | xe -LL -s '
                set -eu
                IFS=$(printf "\t")

                for mark; do
                    read -r id uri title <<< "$mark"
                    id=$("$QUTEBROWSER_SYNC" -i "${id}00")

                    printf "%s\t%s\t%s\n" "${id}" "${uri}" "${title}"
                done
            ' \
            | sort -snk1 \
            | cut -d' ' -f2- \
            | teip -d $'\t' -f1,2,3 -- jq -Rr '@json' \
            | tr '\t' '\n' \
            | xe -N0 -L printf '[ %s, %s, %s ]\n' \
            | jq -s \
                --argjson modified_unix "${qm_modified_unix}" '
                map({
                    data: {
                      parentid: "toolbar",
                      parentName: "toolbar",
                      id: .[0],
                      type: "bookmark",
                      title: .[2],
                      bmkUri: .[1],
                    },
                    id: .[0],
                    modified_unix: $modified_unix
                  }
                )
            '
    )
    log 2 "${QUTEBROWSER_SYNC_DEVICE}: got local quickmarks records"
    log 4 "${QUTEBROWSER_SYNC_DEVICE}: $(jq <<<"${qm_local_records}")"

    # Older on remote.
    push_records=$(
        jq \
            --argjson modified_unix "${modified_unix}" \
            'map(select(.modified_unix <= $modified_unix))' \
            <<<"${remote_records}"
    )
    log 2 "${QUTEBROWSER_SYNC_DEVICE}: got push records (<= ${modified_unix})"
    log 4 "${QUTEBROWSER_SYNC_DEVICE}: $(jq <<<"${push_records}")"

    # Newer on remote.
    pull_records=$(
        jq \
            --argjson modified_unix "${modified_unix}" \
            'map(select(.modified_unix > $modified_unix))' \
            <<<"${remote_records}"
    )
    log 2 "${QUTEBROWSER_SYNC_DEVICE}: got pull records (> ${modified_unix})"
    log 4 "${QUTEBROWSER_SYNC_DEVICE}: $(jq <<<"${pull_records}")"

    # local remote_ids bm_local_ids qm_local_ids push_ids pull_ids
    # mapfile -t remote_ids < <(jq -r 'map(.id)[]' <<<"${remote_records}")
    # mapfile -t bm_local_ids < <(jq -r 'map(.id)[]' <<<"${bm_local_records}")
    # mapfile -t qm_local_ids < <(jq -r 'map(.id)[]' <<<"${qm_local_records}")
    mapfile -t push_ids < <(jq -r 'map(.id)[]' <<<"${push_records}")
    mapfile -t pull_ids < <(jq -r 'map(.id)[]' <<<"${pull_records}")
    log 2 "${QUTEBROWSER_SYNC_DEVICE}: collected ids"

    log 2 "${QUTEBROWSER_SYNC_DEVICE}: pushing ${#push_ids[@]} records..."
    local id record
    for id in "${push_ids[@]}"; do
        record=$(jq -e --arg id "${id}" 'map(select(.id == $id))[]' <<<"${bm_local_records}")
        log 3 "${QUTEBROWSER_SYNC_DEVICE}: pushing record ${id}"
        edo ifne ffsclient update bookmarks "${id}" --create --data-stdin <<<"${record}"
        log 3 "${QUTEBROWSER_SYNC_DEVICE}: pushed record ${id}"
    done

    log 2 "${QUTEBROWSER_SYNC_DEVICE}: pulling ${#pull_ids[@]} records..."
    for id in "${pull_ids[@]}"; do
        record=$(jq -e --arg id "${id}" 'map(select(.id == $id))[]' <<<"${remote_records}")
        log 3 "${QUTEBROWSER_SYNC_DEVICE}: pulling record ${id}"

        local parentid title uri
        record=$(
            jq -r '
                "parentid=\(.data.parentid | @sh)",
                "title=\(.data.title| @sh)",
                "uri=\(.data.bmkUri | @sh)"
            ' <<<"${record}"
        )
        eval "${record}"

        case "${parentid}" in
            "toolbar")
                if pgrep -u "${USER}" qutebrowser >/dev/null 2>&1; then
                    qutebrowser :quickmark-add "${uri}" "${title}"
                else
                    {
                        grep -vF "${title} " "${QUTEBROWSER_QUICKMARKS}"
                        printf '%s %s\n' "${title}" "${uri}"
                    } | sort | sponge "${QUTEBROWSER_QUICKMARKS}"
                fi
                ;;
            *)
                if pgrep -u "${USER}" qutebrowser >/dev/null 2>&1; then
                    if grep -qF "${uri} " "${QUTEBROWSER_QUICKMARKS}"; then
                        qutebrowser :bookmark-add "${uri}" "${title}"
                    else
                        qutebrowser :bookmark-del "${uri}"
                        qutebrowser :bookmark-add "${uri}" "${title}"
                    fi
                else
                    {
                        grep -vF "${uri} " "${QUTEBROWSER_BOOKMARKS}"
                        printf '%s %s\n' "${uri}" "${title}"
                    } | sort | sponge "${QUTEBROWSER_BOOKMARKS}"
                fi
                ;;
        esac
        log 3 "${QUTEBROWSER_SYNC_DEVICE}: pulled record ${id}"
    done
}

login() {
    local username="$1"
    local password="$2"
    local client

    ffsclient login "${username}" "${password}" --device-name="${QUTEBROWSER_SYNC_DEVICE}" || exit $?

    client=$(
        jq -n --arg uname "$(uname)" '{
          id: $ENV.QUTEBROWSER_SYNC_DEVICE_ID,
          name: $ENV.QUTEBROWSER_SYNC_DEVICE,
          protocols: [ "1.5" ],
          type: "desktop",
          application: "qutebrowser-sync",
          os: $uname
        }'
    )

    ffsclient update clients "${QUTEBROWSER_SYNC_DEVICE_ID}" --create --data-stdin --quiet <<<"${client}"
}

# SC2016: Don't warn about expressions in single quotes, they're used by `xe`.
# SC2317: Don't warn about "unreachable commands".
# shellcheck disable=SC2016,SC2317
sync_tabs() {
    log 1 "${QUTEBROWSER_SYNC_DEVICE}: synchronizing tabs..."

    log 1 "${QUTEBROWSER_SYNC_DEVICE}: pulling tabs from remote..."

    local remote_tabs remote_sessions
    remote_tabs=$(
        ffsclient list tabs --decoded --format json \
            | jq 'map(
              try .data |= fromjson
                | select(.data.deleted != true)
            )'
    )
    mapfile -t remote_sessions < <(jq -r 'map(.data.clientName // empty)[]' <<<"${remote_tabs}")

    local record
    for remote_session in "${remote_sessions[@]}"; do
        [[ "${remote_session}" == "${QUTEBROWSER_SYNC_DEVICE}" ]] && continue
        record=$(jq --arg session "${remote_session}" 'map(select(.data.clientName == $session))[]' <<<"${remote_tabs[@]}")

        remote_session_name=$(jq -r '.data.clientName' <<<"${record}")
        remote_session_name=${remote_session_name// /_}

        touch "${QUTEBROWSER_SESSIONS}"/"${remote_session_name}".yml

        ifne jq '
            .data | {
              windows: [
                {
                  active: true,
                  tabs: (
                    .tabs
                      | map(
                        .title as $title
                          | (.lastUsed | todate[:-1]) as $last_visited
                          | {
                            history: (.urlHistory | map({
                              lastUsed: $last_visited,
                              title: $title,
                              url: .
                            }))
                        }
                      )
                  )
                }
              ]
            }' <<<"${record}" \
            | ifne sponge "${QUTEBROWSER_SESSIONS}"/"${remote_session_name}".yml
    done
    exit

    local local_session local_session_name

    # get the most recent session file that was modified
    local_session=$(
        find "${QUTEBROWSER_SESSIONS}" \
            -maxdepth 1 \
            -type f \
            -name '*.yml' \
            -exec stat -c $'%Y\t%n' {} + \
            | sort -t $'\t' -k1nr \
            | head -n1 \
            | cut -f2
    )
    local_session_name=${local_session##*/}
    local_session_name=${local_session_name%.yml}
    log 2 "${QUTEBROWSER_SYNC_DEVICE}: synchronizing tabs from session \"${local_session_name}\"..."

    local local_tabs local_tabs_count
    local_tabs=$(
        yq -p yaml -o json "${local_session}" \
            | jq -rc '
                {
                  clientName: $ENV.QUTEBROWSER_SYNC_DEVICE,
                  id: $ENV.QUTEBROWSER_SYNC_DEVICE_ID,
                  tabs: (
                    .windows
                      | map(.tabs[]
                        | .history |= reverse
                        | {
                          title: (.history[0].title),
                          urlHistory: (.history | reverse | map(.url)),
                          lastUsed: (.history[0].last_visited + "Z" | fromdate)
                        }
                      )
                    )
                }'
    )
    echo "${local_tabs}" >&2
    local_tabs_count=$(jq '.tabs | length' <<<"${local_tabs}")
    log 2 "${QUTEBROWSER_SYNC_DEVICE}: session has ${local_tabs_count} tab(s)"

    ffsclient update tabs "${QUTEBROWSER_SYNC_DEVICE_ID}" --create --quiet --data-stdin <<<"${local_tabs}"
}

: "${XDG_CACHE_HOME:=${HOME}/.cache}"
: "${XDG_CONFIG_HOME:=${HOME}/.config}"
: "${XDG_DATA_HOME:=${HOME}/.local/share}"

export QUTEBROWSER_SYNC="$0"
: "${QUTEBROWSER_SYNC_SESSION:=${XDG_CONFIG_HOME}/qutebrowser/sync.secret}"

# 0 quiet
# 1 normal
# 2 verbose
# 3 debug
: "${QUTEBROWSER_SYNC_VERBOSITY:=1}"

: "${QUTEBROWSER_SYNC_DRY_RUN:=false}"

: "${QUTEBROWSER_SYNC_JOBS:=4}"

: "${QUTEBROWSER_SYNC_DEVICE:=$(id -un)@$(hostname).$(hostname -y):qutebrowser}"

: "${QUTEBROWSER_SYNC_OPERATION:=default}"

: "${QUTEBROWSER_BOOKMARKS:=${XDG_CONFIG_HOME}/qutebrowser/bookmarks/urls}"
: "${QUTEBROWSER_QUICKMARKS:=${XDG_CONFIG_HOME}/qutebrowser/quickmarks}"
: "${QUTEBROWSER_SESSIONS:=${XDG_DATA_HOME}/qutebrowser/sessions}"

while getopts :MTliFvd:j: arg >/dev/null 2>&1; do
    case "${arg}" in
        M) QUTEBROWSER_SYNC_OPERATION=sync_marks ;;
        T) QUTEBROWSER_SYNC_OPERATION=sync_tabs ;;

        l) QUTEBROWSER_SYNC_OPERATION=login ;;

        i) QUTEBROWSER_SYNC_OPERATION=generate_id ;;
        F) QUTEBROWSER_SYNC_OPERATION=ffsclient ;;

        v) QUTEBROWSER_SYNC_VERBOSITY=$((QUTEBROWSER_SYNC_VERBOSITY + 1)) ;;

        d) QUTEBROWSER_SYNC_DEVICE="${OPTARG}" ;;
        j) QUTEBROWSER_SYNC_JOBS="${OPTARG}" ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

QUTEBROWSER_SYNC_DEVICE_ID=$(generate_id "${QUTEBROWSER_SYNC_DEVICE}")
export QUTEBROWSER_SYNC_DEVICE QUTEBROWSER_SYNC_DEVICE_ID

[[ "${QUTEBROWSER_SYNC_VERBOSITY}" -gt 5 ]] && set -x

case "${QUTEBROWSER_SYNC_OPERATION}" in
    login | generate_id | ffsclient) : ;;
    *)
        if ! [[ -e "${QUTEBROWSER_SYNC_SESSION}" ]]; then
            printf 'error: you need to login first\n' >&2
            exit 127
        fi
        ;;
esac

case "${QUTEBROWSER_SYNC_OPERATION}" in
    default)
        sync_marks
        sync_tabs
        ;;

    sync_marks) sync_marks ;;
    sync_tabs) sync_tabs ;;

    login)
        [[ "$#" -eq 2 ]] || usage
        login "$1" "$2"
        ;;

    ffsclient) ffsclient "$@" ;;
    generate_id) generate_id "$@" ;;

    *) usage ;;
esac
