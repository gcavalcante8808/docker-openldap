#!/bin/bash

set -e

LDIF_FILE="/tmp/auditlog.ldif"
if [[ ! -z ${LDAP_TLS_CA} && ! -z ${LDAP_TLS_CERT} && ! -z ${LDAP_TLS_KEY} ]]; then
   	echo "Creating LDIF File"
	cat <<-EOT > ${LDIF_FILE}
		dn: cn=module,cn=config
		cn: module
		objectClass: olcModuleList
		olcModuleLoad: auditlog
		olcModulePath: /usr/lib/openldap

		dn: olcOverlay={0}auditlog,olcDatabase={0}config,cn=config
		objectClass: olcOverlayConfig
		objectClass: olcAuditlogConfig
		olcOverlay: {0}auditlog
		olcAuditlogFile: /tmp/auditlog-config.ldif

		dn: olcOverlay={0}auditlog,olcDatabase={1}mdb,cn=config
		objectClass: olcOverlayConfig
		objectClass: olcAuditlogConfig
		olcOverlay: {0}auditlog
		olcAuditlogFile: /tmp/auditlog-mdb.ldif

	EOT

	echo "Pulling ldif into cn=config"
	ldapadd -x -D "cn=admin,cn=config" -w ${LDAP_ADMIN_PASSWORD} -f ${LDIF_FILE}
	echo "Operation finished."

fi
