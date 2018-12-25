#!/bin/bash

if [ ! -d "/data/schema"]; then
  cp -Ra /etc/openldap/* /data/
  chown -R ldap:ldap /data
fi
