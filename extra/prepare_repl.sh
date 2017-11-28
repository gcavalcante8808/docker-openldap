#!/bin/bash

set -e

setid () {
	LDIF_FILE="/tmp/setid.ldif"
	cat <<-EOT >${LDIF_FILE}
		dn: cn=config
		changetype: modify
		add: olcServerID
		olcServerID: ${LDAP_ID}
	EOT
	
	echo "Define Server ID as ${LDAP_ID}"
	ldapadd -x -D "cn=admin,cn=config" -w ${LDAP_ADMIN_PASSWORD} -f ${LDIF_FILE}
	echo "Operation finished."
}

load_syncprov () {
	LDIF_FILE="/tmp/load_syncprov.ldif"
	cat <<-EOT >${LDIF_FILE}
		dn: cn=module{0},cn=config
		cn: module
		objectClass: olcModuleList
		olcModuleLoad: syncprov
		olcModulePath: /usr/lib/openldap
	EOT
	
	echo "Loading SyncProv Module"
	ldapadd -x -D "cn=admin,cn=config" -w ${LDAP_ADMIN_PASSWORD} -f ${LDIF_FILE}
	echo "Operation finished."
}

enable_syncprov () {
	LDIF_FILE="/tmp/enable_syncprov.ldif"
	cat <<-EOT >${LDIF_FILE}
		dn: olcOverlay={0}syncprov,olcDatabase={0}config,cn=config
		objectClass: olcOverlayConfig
		objectClass: olcSyncProvConfig
		olcOverlay: syncprov
	EOT
	
	echo "Enabling SyncProv Module"
	ldapadd -x -D "cn=admin,cn=config" -w ${LDAP_ADMIN_PASSWORD} -f ${LDIF_FILE}
	echo "Operation finished."
	
}

map_rid () {
	LDIF_FILE="/tmp/map_rid.ldif"
	cat <<-EOT >${LDIF_FILE}
		dn: cn=config
		changetype: modify
		replace: olcServerID
		olcServerID: ${LDAP_ID} ldap://${LDAP_ADDRESS}/
	EOT
	
	echo "Mapping RID ${LDAP_ID} to ${LDAP_ADDRESS}"
	ldapadd -x -D "cn=admin,cn=config" -w ${LDAP_ADMIN_PASSWORD} -f ${LDIF_FILE}
	echo "Operation finished."
	
}

setid
load_syncprov
enable_syncprov
map_rid
