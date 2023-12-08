FROM gcr.io/distroless/static-debian10:debug

ENV DEBIAN_FRONTEND=noninteractive
RUN echo "slapd/root_password password secret" | debconf-set-selections && \
   echo "slapd/root_password_again password secret" | debconf-set-selections && \
   apt-get update && apt-get install -y --no-install-recommends slapd ldap-utils ldapscripts systemctl && \
   rm -rf /var/lib/apt/lists/*


# Copy LDAP initialization files to the container

COPY ./ldap-init/ /ldap-init

# Create necessary directories and clean up

RUN rm -r /etc/ldap/slapd.d/ && \
    rm -rf /var/lib/ldap/* && \
    chmod +x /ldap-init/entrypoint.sh

# Set the working directory

WORKDIR /ldap-init

# Expose port 389 for LDAP

EXPOSE 389

# Set environment variable for LDAP URIs

ENV LDAP_URIS="ldap:///"

# Define the command to run when the container starts

CMD ["./entrypoint.sh"]