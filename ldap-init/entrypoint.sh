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



    systemctl enable slapd.service
    systemctl start slapd.service



    echo "ldap status"
    systemctl status slapd.service
