#!/usr/bin/env bash
set -eo pipefail



conf_arrow_flight_sql_port(){
    file="$1"
    value="$2"
    ## check if file is writable
    if [ -w "$file" ]; then
        exist=$(grep -v "^#" < "${file}" | yq -p=props -o=yaml | yq 'has("arrow_flight_sql_port")')

        if [ "true" = "$exist" ]; then
            value_default=$(grep -v "^#" < "${file}" | yq -p=props -o=yaml | yq '.arrow_flight_sql_port')
            if [[ "${value_default}" != "${value}" ]]; then                
                sed -i "s/^arrow_flight_sql_port.*/arrow_flight_sql_port = ${value}/g" "$file"
            fi
        fi
    fi
}

conf_enable_fqdn_mode(){

    if [[ "${DORIS_VERSION}" < "2.0.0" ]]; then
        return 0;
    fi

    file="$1"
    value="$2"
    ## check if file is writable
    if [ -w "$file" ]; then
        exist=$(grep -v "^#" < "${file}" | yq -p=props -o=yaml | yq 'has("enable_fqdn_mode")')

        if [ "true" = "$exist" ]; then
            ## modify if existed
            value_default=$(grep -v "^#" < "${file}" | yq -p=props -o=yaml | yq '.enable_fqdn_mode')
            if [[ "${value_default}" != "${value}" ]]; then
                sed -i "s/^enable_fqdn_mode.*/enable_fqdn_mode = ${value}/g" "$file"
            fi
        else
            echo "enable_fqdn_mode = ${value}" >> "$file" ## append
        fi
    fi
}

_main() {
    if [ -n "$TZ" ]; then
        ( ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone ) || true
    fi
    ulimit -n "${ULIMIT_NOFILE:-1000000}" || true
    ulimit -a || true
    swapoff -a || true

    conf_arrow_flight_sql_port "/opt/apache-doris/fe/conf/fe.conf" "${FE_ARROW_FLIGHT_SQL_PORT}"
    conf_arrow_flight_sql_port "/opt/apache-doris/be/conf/be.conf" "${BE_ARROW_FLIGHT_SQL_PORT}"
    conf_enable_fqdn_mode "/opt/apache-doris/fe/conf/fe.conf" "${ENABLE_FQDN_MODE}"



    if grep -q -i "stand" <<< "${RUN_MODE}"; then
        touch /etc/s6-overlay/s6-rc.d/user/contents.d/be
        touch /etc/s6-overlay/s6-rc.d/user/contents.d/fe
        touch /etc/s6-overlay/s6-rc.d/user/contents.d/cluster
    elif grep -q -i "fe" <<< "${RUN_MODE}"; then
        touch /etc/s6-overlay/s6-rc.d/user/contents.d/fe
        touch /etc/s6-overlay/s6-rc.d/user/contents.d/cluster
    elif grep -q -i "be" <<< "${RUN_MODE}"; then
        touch /etc/s6-overlay/s6-rc.d/user/contents.d/be
        touch /etc/s6-overlay/s6-rc.d/user/contents.d/cluster
    fi



    exec /init
}

_main "$@"
