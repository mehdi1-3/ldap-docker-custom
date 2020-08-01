FROM alpine:3.8

RUN apk --update add openldap openldap-back-mdb openldap-clients

COPY ./ldap-init/ /ldap-init

RUN mkdir -p /run/openldap && \
    mkdir -p /etc/openldap/slapd.d && \
    mkdir -p /var/lib/openldap/openldap-data && \
    rm -r /etc/openldap/* && \
    rm -r /var/lib/openldap/openldap-data/* && \
    chmod +x /ldap-init/entrypoint.sh

WORKDIR /ldap-init

ENV LDAP_URIS="ldap:///"

CMD [ "./entrypoint.sh" ]