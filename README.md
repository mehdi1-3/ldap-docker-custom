# ldap-docker

A docker image of LDAP server and LDAP client based on openldap.

## Environments

| environment | default         | required | description |
|-------------|-----------------|----------|-------------|
| `ROOT_DN_PW`|                 | yes      | password for rootdn  |
| `ROOT_DN`   |                 | yes      | rootdn |
| `SUFFIX`    |                 | yes      | suffix |
| `LDAP_URIS` | `ldaps:///`     | no       | LDAP URIs without TLS |
| `LDAPS_URIS`| ` `             | no       | LDAP URIs using TLS |
| `CERT`      | ` `             | no       | path to certificate |
| `PRIVKEY`   | ` `             | no       | path to private key|
| `CA_CERT`   | ` `             | no       | path to CA certificate |

* `ROOT_DN_PW` is hashed and stored in `/etc/openldap/slapd.conf`.
* At least one or more URIs must be given by `LDAP_URIS` or `LDAPS_URIS`
* If `LDAPS_URIS`, `CERT` and `PRIVKEY` are given, TLS is enabled; otherwise, TLS is disabled.

With the above environments, the container will generate the following `/etc/openldap/slapd.conf`.
```conf
# Schemas
include  /etc/openldap/schema/core.schema
include     /etc/openldap/schema/cosine.schema
include     /etc/openldap/schema/inetorgperson.schema
include     /etc/openldap/schema/nis.schema

# PID files
pidfile  /run/openldap/slapd.pid
argsfile /run/openldap/slapd.args

# Modules
modulepath /usr/lib/openldap
moduleload back_mdb.so

# MDB
database mdb
maxsize  1073741824
directory /var/lib/openldap/openldap-data

suffix  "SUFFIX"
rootdn  "ROOT_DN"
rootpw  ROOT_DN_PW

# Indices to maintain
index objectClass eq

### TLS (https://www.openldap.org/doc/admin24/tls.html)
TLSCACertificateFile    CA_CERT
TLSCertificateFile  CERT
TLSCertificateKeyFile   PRIVKEY
```

## Volumes

* LDAP database is stored in `/var/lib/openldap/openldap-data`.
* Configuration file of slapd is stored in `/etc/openldap`.

## Initialization

* If a container has `/etc/openldap/slapd.conf`, the container uses the existing file.
* If a container does not have `/etc/openldap/slapd.conf`, the container generates `/etc/openldap/slapd.conf` and initialize it based on the given environments.
* If an LDAP database is missing, a new LDAP database is generated in `/var/lib/openldap/openldap-data`.

## Example

### Prepare self signed certificate

Enter a docker container that contains openssl.
```sh
docker run -it -v $(pwd)/certificates:/certificates jumpaku/openssl-docker bash
```

Generate a self signed certificate using openssl.
```sh
CERT_PATH=/certificates
SERVER_NAME=ldap-server

openssl req -new -newkey rsa:2048 -nodes -out "$CERT_PATH/ca_csr.pem" -keyout "$CERT_PATH/ca_privkey.pem" -subj="/C=JP"
openssl req -x509 -key "$CERT_PATH/ca_privkey.pem" -in "$CERT_PATH/ca_csr.pem" -out "$CERT_PATH/ca_cert.pem" -days 356
openssl req -new -newkey rsa:2048 -nodes -out "$CERT_PATH/csr.pem" -keyout "$CERT_PATH/privkey.pem" -subj="/CN=$SERVER_NAME"
SERIAL="0x$(echo -n $SERVER_NAME | openssl sha256 | awk '{print $2}')"
openssl x509 -req -CA "$CERT_PATH/ca_cert.pem" -CAkey "$CERT_PATH/ca_privkey.pem" -set_serial "$SERIAL" -in "$CERT_PATH/csr.pem" -out "$CERT_PATH/cert.pem" -days 365
```

### Prepare `docker-compose.yml`

```yml
version: '3'

services: 

  ldap-server:
    image: 'jumpaku/ldap-docker'
    environment:
      - "ROOT_DN_PW=ldap_rootdn_pw"
      - "ROOT_DN=cn=admin,dc=example,dc=com"
      - "SUFFIX=dc=example,dc=com"
      #- "LDAP_URIS="
      - "LDAPS_URIS=ldaps://ldap-server/"
      - "CERT=/certificates/cert.pem"
      - "PRIVKEY=/certificates/privkey.pem"
    volumes:
      #- './db/:/var/lib/openldap/openldap-data' 
      #- './conf/:/etc/openldap' 
      - './certificates:/certificates'

  ldap-client:
    image: 'jumpaku/ldap-docker'
    # Set TLS_REQCERT never, to use a self signed cetificate. Be careful spelling.
    command: ["ash", "-c", "echo 'TLS_REQCERT never' > /etc/openldap/ldap.conf; ash"]
    environment:
      - "BIND_DN_PW=ldap_rootdn_pw"
      - "BIND_DN=cn=admin,dc=example,dc=com"
      - "BASE_DN=dc=example,dc=com"
      - "LDAP_SERVER_URI=ldaps://ldap-server/"
```

### Try an LDAP operation in the LDAP server

Run the LDAP server as follows:
```sh
docker-compose up --build -d ldap-server
```

Enter the LDAP server as follows:
```sh
docker-compose exec ldap-server ash
```

Execute slapcat to display entries as follows:
```sh
slapcat
```

### Try LDAP operations in the LDAP client

Run the LDAP server as follows:
```sh
docker-compose up --build -d ldap-server
```

Enter an LDAP client as follows:
```sh
docker-compose run ldap-client ash -c "echo 'TLS_REQCERT never' > /etc/openldap/ldap.conf; ash"
```

Execute the following LDAP operations.

* ldapsearch
```sh
ldapsearch -x -Z -H "${LDAP_SERVER_URI}" -D "${BIND_DN}" -w "${BIND_DN_PW}" -b "${BASE_DN}" "(objectClass=*)"
```

* ldapadd
```sh
cat <<END | ldapadd -c -x -Z -H "${LDAP_SERVER_URI}" -D "${BIND_DN}" -w "${BIND_DN_PW}"
# entry for users
dn: ou=users,dc=example,dc=com
objectClass: organizationalUnit
ou: users

dn: cn=user1,ou=users,dc=example,dc=com
objectClass: inetOrgPerson
cn: user1
sn: user1

dn: cn=user2,ou=users,dc=example,dc=com
objectClass: inetOrgPerson
cn: user2
sn: user2

dn: cn=user3,ou=users,dc=example,dc=com
objectClass: inetOrgPerson
cn: user3
sn: user3
END

```

* ldapdelete
```sh
cat <<END | ldapdelete -c -x -H "${LDAP_SERVER_URI}" -D "${BIND_DN}" -w "${BIND_DN_PW}"
cn=user1,ou=users,dc=example,dc=com
cn=user2,ou=users,dc=example,dc=com
END

```
