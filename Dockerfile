# Use multi-stage builds
FROM debian:buster-backports as builder

ENV DEBIAN_FRONTEND=noninteractive

RUN echo "slapd/root_password password secret" | debconf-set-selections && \
    echo "slapd/root_password_again password secret" | debconf-set-selections && \
    apt-get update --no-cache && apt-get install -y --no-install-recommends slapd ldap-utils ldapscripts systemctl && \
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

# Use a non-root user
RUN useradd -ms /bin/bash ldapuser
USER ldapuser

CMD ["./entrypoint.sh"]