#!/bin/sh

LDAP_INIT="/ldap-init"
SLAPD_CONF="/etc/openldap/slapd.conf"
DATA_MDB="/var/lib/openldap/openldap-data/data.mdb"

if [ -e "${SLAPD_CONF}" ]; then 
    echo "Initialization is skipped because ${SLAPD_CONF} already exists."
    slaptest -u -f "${SLAPD_CONF}" || ( echo "Invalid configuration" && exit 1 )
else
    echo "Initializing ${SLAPD_CONF}"

    cp -R /ldap-init/conf/* /etc/openldap/

    sed -i "s|ROOT_DN_PW|$(slappasswd -s ${ROOT_DN_PW})|" "${SLAPD_CONF}"
    sed -i "s|ROOT_DN|${ROOT_DN}|g" "${SLAPD_CONF}"
    sed -i "s|SUFFIX|${SUFFIX}|g" "${SLAPD_CONF}"

    if [ -n "${LDAPS_URIS}" ] && [ -e "${CERT}" ] && [ -e "${PRIVKEY}" ]; then
        if [ -e "${CA_CERT}" ]; then
            sed -i -e "s|CA_CERT|${CA_CERT}|g" "${SLAPD_CONF}"
        else
            sed -i -e "s|^.*CA_CERT.*$||g" "${SLAPD_CONF}"
        fi
        sed -i -e "s|CERT|${CERT}|g" "${SLAPD_CONF}"
        sed -i -e "s|PRIVKEY|${PRIVKEY}|g" "${SLAPD_CONF}"

    else
        LDAPS_URIS=""
        sed -i -e "s|^.*CA_CERT.*$||g" "${SLAPD_CONF}"
        sed -i -e "s|^.*CERT.*$||g" "${SLAPD_CONF}"
        sed -i -e "s|^.*PRIVKEY.*$||g" "${SLAPD_CONF}"
    fi

    slaptest -u -f "${SLAPD_CONF}" || ( echo "Invalid configuration" && exit 1 )

    if [ -e "$DATA_MDB" ]; then
        echo "$DATA_MDB cannot be initialized because it already exists."
        exit 1
    fi

    echo "Initializing $DATA_MDB."
    rm -r /var/lib/openldap/openldap-data
    mkdir -p /var/lib/openldap/openldap-data

    ROOT_DN_CN=$(echo "${ROOT_DN}" | awk -F "," '{ print $1 }' | sed -e "s|^.*=||g")
    SUFFIX_DC=$(echo "${SUFFIX}" | awk -F "," '{ print $1 }' | sed -e "s|^.*=||g")
    cat "${LDAP_INIT}/rootdn.ldif" \
        | sed -e "s|ROOT_DN_CN|${ROOT_DN_CN}|g" \
        | sed -e "s|ROOT_DN|${ROOT_DN}|g" \
        | sed -e "s|SUFFIX_DC|${SUFFIX_DC}|g" \
        | sed -e "s|SUFFIX|${SUFFIX}|g" \
        | slapadd;
fi

echo "Start: slapd -h \"$LDAP_URIS $LDAPS_URIS\""
slapd -h "$LDAP_URIS $LDAPS_URIS" -d 256