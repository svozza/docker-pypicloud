FROM phusion/baseimage:0.10.0
MAINTAINER Steven Arcangeli <stevearc@stevearc.com>

# Default credentials: admin/secret
# Use ppc-gen-password to generate new value.
ENV PYPICLOUD_VERSION=1.0.9 \
    CONFD_VERSION=0.16.0 \
    PYPI_ADMIN_PASSWORD='$6$rounds=704055$kq8HTiZC50zoffwq$T335/H9UxRegwAxcuTUggt.ip2CBpP18wTxOAGpK8DLBZ3jC2yVklFQxRtOd5tHqmzaxDIuq0VUJb/lzaLhNW0' \
    PYPI_DB_URL=sqlite:////var/lib/pypicloud/db.sqlite \
    PYPI_AUTH_DB_URL=sqlite:////var/lib/pypicloud/db.sqlite \
    PYPI_SESSION_ENCRYPT_KEY=replaceme \
    PYPI_SESSION_VALIDATE_KEY=replaceme \
    PYPI_SESSION_SECURE=false \
    PYPI_FALLBACK=redirect \
    PYPI_FALLBACK_URL=https://pypi.python.org/simple \
    PYPI_STORAGE=file \
    PYPI_STORAGE_DIR=/var/lib/pypicloud/packages \
    PYPI_STORAGE_BUCKET=changeme \
    PYPI_AUTH=config \
    PYPI_DEFAULT_READ=authenticated \
    PYPI_CACHE_UPDATE=authenticated \
    PYPI_HTTP=0.0.0.0:8080 \
    PYPI_PROCESSES=20 \
    PYPI_SSL_KEY= \
    PYPI_SSL_CRT= \
    PYPI_LDAP_URL= \
    PYPI_LDAP_SERVICE_DN= \
    PYPI_LDAP_SERVICE_PASSWORD= \
    PYPI_LDAP_BASEDN= \
    PYPI_LDAP_USERSEARCH= \
    PYPI_LDAP_IDFIELD= \
    PYPI_LDAP_ADMIN_FIELD= \
    PYPI_LDAP_ADMIN_DNS=

# Installing uwsgi and pypicloud in same pip command fails for some reason.
RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -qy python3-pip \
     python3-dev libldap2-dev libsasl2-dev libmysqlclient-dev libffi-dev libssl-dev \
  && pip3 install pypicloud[all_plugins]==$PYPICLOUD_VERSION requests uwsgi \
     pastescript mysqlclient psycopg2-binary \
  # Create the pypicloud user
  && groupadd -r pypicloud \
  && useradd -r -g pypicloud -d /var/lib/pypicloud -m pypicloud \
  # Make sure this directory exists for the baseimage init
  && mkdir -p /etc/my_init.d

COPY config.ini.tmpl /etc/confd/templates/config.ini.tmpl
COPY config.ini.toml /etc/confd/conf.d/config.ini.toml

ADD https://github.com/kelseyhightower/confd/releases/download/v${CONFD_VERSION}/confd-${CONFD_VERSION}-linux-amd64 /usr/local/bin/confd
RUN chmod +x /usr/local/bin/confd

EXPOSE 8080

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["pypi"]
