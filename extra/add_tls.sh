#!/bin/bash

set -e

if [[ ! -z ${LDAP_TLS_CA} && ! -z ${LDAP_TLS_CERT} && ! -z ${LDAP_TLS_KEY} ]]; then
   	echo "Creating LDIF File"
	cat <<-EOT > /tmp/tls.ldif
		dn: cn=config
		add: olcTLSCACertificateFile
		olcTLSCACertificateFile: ${LDAP_TLS_CA}
		-
		add: olcTLSCertificateFile
		olcTLSCertificateFile: ${LDAP_TLS_CERT}
		-
		add: olcTLSCertificateKeyFile
		olcTLSCertificateKeyFile: ${LDAP_TLS_KEY}
	EOT
		
	echo "Pulling ldif into cn=config"
	ldapmodify -x -D "cn=admin,cn=config" -w ${LDAP_ADMIN_PASSWORD} -f /tmp/tls.ldif
	echo "Operation finished."

fi
