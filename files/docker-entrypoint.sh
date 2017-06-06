#!/bin/bash

set -e

add_tls () {
	. extra/add_tls.sh
}

add_memberof () {
	. extra/add_memberof.sh
}

add_refint () {
	. extra/add_refint.sh
}

add_auditlog () {
	. extra/add_auditlog.sh
}

prepare_repl () {
	. extra/prepare_repl.sh
}

setUp () {
	if [ -z "${LDAP_DB_DATA}" ]; then
		echo "No DB Dir specified for openldap. Using /var/lib/openldap/openldap-data"
		LDAP_DB_DATA="/var/lib/openldap/openldap-data"
	fi

	if [ -z "${LDAP_DOMAIN}" ]; then
		echo "No Domain provided. Using example"
		LDAP_DOMAIN="example"
	fi
	
	if [ -z "${LDAP_SUFFIX}" ]; then
		echo "No Suffix provided. Using dc=example,dc=com"
		LDAP_SUFFIX="dc=example,dc=com"
	fi
	if [ -z "${LDAP_ADMIN_PRINCIPAL}" ]; then
		echo "No Admin Provided. Using cn=admin as default"
		LDAP_ADMIN_PRINCIPAL="cn=admin,${LDAP_SUFFIX}"
	fi

	if [ -z "${LDAP_ADMIN_PASSWORD}" ]; then
		echo "No Admin Password Provided. Using 'LazyPass' as default"
		LDAP_ADMIN_PASSWORD=LazyPass
	fi

	if [ -z "${LDAP_DEBUG_LEVEL}" ]; then
		echo "No LDAP Debug level defined. Using 32768"
		LDAP_DEBUG_LEVEL=32768
	fi

	if [ ! -d /etc/openldap/slapd.d ]; then
		echo "Slapd.d directory not founding. Bootstraping one ... "
		mkdir -p /etc/openldap/slapd.d
		
		echo "Creating DB Files"
		slapd -V
		killall slapd
		 
		cat <<-EOT > /etc/openldap/slapd.conf

	include     /etc/openldap/schema/core.schema
	include     /etc/openldap/schema/collective.schema
	include     /etc/openldap/schema/cosine.schema
	include     /etc/openldap/schema/inetorgperson.schema
	include     /etc/openldap/schema/nis.schema
	include     /etc/openldap/schema/ppolicy.schema
	include     /etc/openldap/schema/dyngroup.schema

	pidfile /var/run/openldap/slapd.pid
	argsfile    /var/run/openldap/slapd.args

	#security ssf=1 update_ssf=112 simple_bind=64

	access to dn.base="" by * read
	access to dn.base="cn=Subschema" by * read
	access to *
	  by self write
	  by users read
	  by anonymous auth

	database    mdb
	maxsize	    1073741824
	suffix      "${LDAP_SUFFIX}"
	rootdn      ${LDAP_ADMIN_PRINCIPAL}
	rootpw      $(slappasswd -s ${LDAP_ADMIN_PASSWORD})
	directory   /var/lib/openldap/openldap-data
	index   objectClass eq

	database    config
	rootdn      "cn=admin,cn=config"
	rootpw      $(slappasswd -s ${LDAP_ADMIN_PASSWORD})

	EOT

		echo "Config File Created. Converting to OLC Format"
		slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d

	fi

	echo "Fixing slapd.d permissions"
	chown -R ldap:ldap ${LDAP_DB_DATA} /etc/openldap/slapd.d /var/run/openldap/
	chmod -R 700 ${LDAP_DB_DATA} /etc/openldap/slapd.d /var/run/openldap/

	echo "Creating Basic DC structure"
	cat <<-EOT >/docker-entrypoint-initdb.d/dc.ldif
		dn: $(echo ${LDAP_SUFFIX} | sed -e 's/\"//g')
		dc: ${LDAP_DOMAIN}
		objectClass: dcObject
		objectClass: organization
		o: ${LDAP_SUFFIX}
	EOT

	if [ ! -f "/.configured" ]; then

		for f in /docker-entrypoint-initdb.d/*; do
		case "$f" in
			*.ldif)   echo "$0: running $f"; slapadd -l "$f" -F /etc/openldap/slapd.d -d1 ;;
			*)        echo "$0: ignoring $f" ;;
		esac
		echo
		done
	 
		touch /.configured
	fi

	# TODO: Add plugins support

}

run_slapd () {
	if [ ! -d "/etc/openldap/slapd.d" ]; then
		setUp
	fi
	
	exec slapd -F /etc/openldap/slapd.d -h ldap://${LDAP_ADDRESS}/ -d ${LDAP_DEBUG_LEVEL}
}


case "$@" in
	run_slapd)
		run_slapd
		;;
	setup)
		setup
		;;
	add_tls)
		add_tls
		;;
	add_repl)
		add_repl
		;;
	add_memberof)
		add_memberof
		;;
	add_refint)
		add_refint
		;;
	add_auditlog)
		add_auditlog
		;;
	prepare_repl)
		prepare_repl
		;;
	*)
		echo "Usage: $0 {run_slapd, setup, add_tls, add_repl, add_memberof, add_refint, add_auditlog, prepare_repl}"
		exit 1
		;;
esac
