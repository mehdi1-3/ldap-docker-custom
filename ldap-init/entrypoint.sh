#!/bin/sh

    systemctl enable slapd.service
    systemctl start slapd.service

    cp /ldap-init/conf/slapd.conf /etc/ldap/slapd.conf
    cp /ldap-init/conf/config.ldif  /etc/ldap/config.ldif
    cp /ldap-init/conf/schema/ia.schema /etc/ldap/schema/ia.schema


    echo "Initializing DATA."
    rm -rf /var/lib/ldap/*
    cp -R /ldap-init/data/* /var/lib/ldap/

    echo "ls /var/lib/ldap/"
    ls /var/lib/ldap/

    chown -R openldap:openldap /var/lib/ldap
    chown -R openldap:openldap /var/lib/sldap


    systemctl enable slapd.service
    systemctl restart slapd.service

    echo "ldap status"
    systemctl status slapd.service

