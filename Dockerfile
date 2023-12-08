# Use multi-stage builds
FROM debian:buster-backports as builder

ENV DEBIAN_FRONTEND=noninteractive

RUN echo 'slapd/root_password password password' | debconf-set-selections &&\
    echo 'slapd/root_password_again password password' | debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
    slapd ldap-utils \
    ldapscripts \
    systemctl && \
    rm -rf /var/lib/apt/lists/*

COPY ./ldap-init/ /ldap-init

RUN rm -r /etc/ldap/slapd.d/ && \
    rm -rf /var/lib/ldap/* && \
    chmod +x /ldap-init/entrypoint.sh

# Final stage
FROM debian:buster-backports

COPY --from=builder / /

WORKDIR /ldap-init

EXPOSE 389

ENV LDAP_URIS="ldap:///"


CMD ["./entrypoint.sh"]