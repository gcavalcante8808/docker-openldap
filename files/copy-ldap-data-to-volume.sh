#!/bin/bash

if [[ ! -d "/data/schema" ]]; then
  cp -Ra /etc/openldap/* /data/
  cp -Ra /var/lib/openldap/openldap-data /ldap-db-data/
  chown -R ldap:ldap /data /ldap-db-data
fi
