#!/bin/bash

set -e

LDIF_FILE="/tmp/refint.ldif"

if [[ ! -f ${LDIF_FILE} ]]; then
   	echo "Creating LDIF File"
	cat <<-EOT > ${LDIF_FILE}
		dn: cn=module,cn=config
		cn: module
		objectClass: olcModuleList
		olcModuleLoad: refint
		olcModulePath: /usr/lib/openldap

		cn: olcOverlay={0}refint,olcDatabase={1}mdb,cn=config
		objectClass: olcConfig
		objectClass: olcOverlayConfig
		objectClass: olcRefintConfig
		objectClass: top
		olcOverlay: {0}refint
		olcRefintAttribute: memberof member manager owner
	EOT
		
	echo "Pulling ldif into cn=config"
	ldapadd -x -D "cn=admin,cn=config" -h ${LDAP_ADDRESS} -w ${LDAP_ADMIN_PASSWORD} -f ${LDIF_FILE}
	echo "Operation finished."

fi
