#!/bin/sh


    cp /ldap-init/conf/slapd.conf /etc/ldap/slapd.conf
    cp /ldap-init/conf/config.ldif  /etc/ldap/config.ldif
    cp /ldap-init/conf/schema/ia.schema /var/lib/ldap/schema/ia.schema



    chmod 777 /usr/lib/ldap/
    chmod 777 /etc/ldap/
    chmod 777 /var/lib/ldap/



    echo "Initializing DATA."
    rm -rf /var/lib/ldap/*
    cp -R /ldap-init/data/* /var/lib/ldap/

    echo "ls /var/lib/ldap/"
    ls /var/lib/ldap/

   chown -R openldap:openldap /var/lib/ldap
   chown -R openldap:openldap /var/lib/sldap
    #ROOT_DN_CN=$(echo "${ROOT_DN}" | awk -F "," '{ print $1 }' | sed -e "s|^.*=||g")
    #SUFFIX_DC=$(echo "${SUFFIX}" | awk -F "," '{ print $1 }' | sed -e "s|^.*=||g")
    #cat "${LDAP_INIT}/rootdn.ldif" \
        #| sed -e "s|ROOT_DN_CN|${ROOT_DN_CN}|g" \
        #| sed -e "s|ROOT_DN|${ROOT_DN}|g" \
        #| sed -e "s|SUFFIX_DC|${SUFFIX_DC}|g" \
        #| sed -e "s|SUFFIX|${SUFFIX}|g" \
        #| slapadd;


systemctl enable slapd.service
systemctl start slapd.service

echo "ldap status"
systemctl status slapd.service
