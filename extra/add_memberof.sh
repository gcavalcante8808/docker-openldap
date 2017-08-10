#!/bin/bash

set -e


LDIF_FILE="/tmp/memberof.ldif"
if [[ ! -f ${LDIF_FILE} ]]; then
   	echo "Creating LDIF File"
	cat <<-EOT > ${LDIF_FILE}
		dn: cn=module,cn=config
		cn: module
		objectClass: olcModuleList
		olcModuleLoad: memberof
		olcModulePath: /usr/lib/openldap

		dn: olcOverlay={0}memberof,olcDatabase={1}mdb,cn=config
		objectClass: olcConfig
		objectClass: olcMemberOf
		objectClass: olcOverlayConfig
		objectClass: top
		olcOverlay: memberof
		olcMemberOfDangling: ignore
		olcMemberOfRefInt: TRUE
		olcMemberOfGroupOC: groupOfNames
		olcMemberOfMemberAD: member
		olcMemberOfMemberOfAD: memberOf
	EOT
		
	echo "Pulling ldif into cn=config"
	ldapadd -x -D "cn=admin,cn=config" -h ${LDAP_ADDRESS} -w ${LDAP_ADMIN_PASSWORD} -f ${LDIF_FILE}
	echo "Operation finished."

fi
