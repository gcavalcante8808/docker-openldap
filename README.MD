What is OpenLDAP?

OpenLDAP is a lightweight implementation of Lightweight Directory Access Protocol. The version available in this image is the version 2.4.

https://wikipedia.org/wiki/OpenLDAP

How to use this image
---------------------

Start a openldap instance

```
    docker run --name openldap -e LDAP_SUFFIX dc=mydomain,dc=com -d gcavalcante8808/openldap
```

This image includes EXPOSE 389 636 (the ldap and ldaps) ports, so standard container linking
will make it automatically available to the linked containers. The default rootdn *cn=admin,dc=example,dc=com* (unless you defined LDAP_ADMIN_PRINCIPAL, check environment variables for more info) will be created with the password *LazyPass*.

You can check defaults used by the docker-compose on the 'example.env' file. TLS support comes enabled by default using previously created certificates (**which shouldn't use in production environments**).

Environment Variables
---------------------

The OpenLDAP image uses several environment variables which are easy to miss. While none of them is required,
they may significantly help you in the directory configuration task.

LDAP_ADDRESS

This Environment variable is **NEEDED** to opendldap operate properly and (later) to use replication. Use a FQDN if possible.

LDAP_DOMAIN

This environment variable is recommended for you to use OpenLDAP Image. This environment variable sets the dc object available by default,
and have a value like "example" if your domain is "example.com". The default domain is "example".

LDAP_SUFFIX

This environment variable is recommended for you to use OpenLDAP Image. This environment variable sets the suffix used by LDAP,
like "dc=enterprise,dc=com". The default suffix is "dc=example,dc=com".

LDAP_ADMIN_PRINCIPAL

Name of the superuser of the directory, something like "cn=root,dc=myenterprise,dc=com". The superuser always have access to the directory.
The default value is "cn=admin,dc=example,dc=com".

LDAP_ADMIN_PASSWORD

Password of the superuser. The defaule value is *LazyPass*. 

**Note*: Do not use parenthesis to specify the password; a hash will be computed from it and write into the openldap database during the first
startup.

LDAP_DEBUG_LEVEL

Used to define the debug level of the directory. By default it do not print too much messages (as stated in level 32768). For possible codes
check the documentation at: http://www.openldap.org/doc/admin24/runningslapd.html

How to extend this image
------------------------

If you would like to do additional initilization in a image derived from this one, add one or more *.ldif files under */docker-entrypoint-initdb.d*. At the end of entrypoint (before it calls exec to throw slapd) it will verify the existence of the file /.configured; if the file is not present, then the files under the directory will be added using slappd utility.

For example, to add an additional user and groups OU's that are defined in a custom.ldif file, add the following to /docker-entrypoint-initdb.d/custom.ldif:

```
    dn: ou=users,dc=example,dc=com
    changetype: add
    objectClass: organizationalUnit
    objectClass: top
    ou: users

    dn: ou=groups,dc=example,dc=com
    changetype: add
    objectClass: organizationalUnit
    objectClass: top
    ou: groups
```

Then, create the following DockerFile:

```
    FROM gcavalcante8808/openldap
    COPY custom.ldif /docker-entrypoint-initdb.d/custom.ldif
```

And build it:

```
    docker build -t myopenldap .
```

Directory Admin Operations
--------------------------

If you want to pull configuration into the directory (everything under cn=config) you can copy your ldif to the container and then use the following shortcut:

```
docker cp my.ldif <CONTAINER>:/my.ldif
docker exec <CONTAINER> /extra/add_config /my.ldif
```

Where "<CONTAINER>" is the name or id of the container; in truth, `add_config` is just a ldapadd shortcut with cn=admin,cn=config privileges. Use with caution.

TLS Support
-----------

If you want to add TLS Support to your LDAP Server, you can use the add_tls command already present on the image, but before, you need to define the following environment variables:

 * LDAP_TLS_CA: path of the public certificate of the ca, eg. "/certs/ca.crt";
 * LDAP_TLS_CERT: path of the public certificate of the server, eg. "/certs/server.crt";
 * LDAP_TLS_KEY: path of the private key for the server certificate, eg. "/certs/server.key";

All files must be readable by the ldap user (uid 100) and key MUST not have a password. With all environment variables set and the container created, use the following commando to add TLS support:

```
   docker exec <YOURCONTAINER> /docker-entrypoint.sh add_tls
```

Groceries
---------

There is some sweet resource available for those want to be productive :D

All resources presented here **are not idempotent**; you just need to activate 'em once. If you try to activate more than once, the ldap server will return errors.

The Overlays presented here have additional information available at: http://www.openldap.org/doc/admin24/overlays.html.

For now, we have support to 'activate' the following overlays/configurations using our entrypoint script:

**MemberOf Overlay**

Usefull to discover from what groups a user is a member (its the reverse of the GroupOfNames).

You can activate the memberof overlay by using the following command:

```
    docker exec <OPENLDAP_CONTAINER> /docker-entrypoint.sh add_memberof
```


**RefInt Overlay**

Update your groups when a dn is removed or updated automagically.

You can activate refint overlay by using the following command:

```
    docker exec <OPENLDAP_CONTAINER> /docker-entrypoint.sh add_refint
```

**AuditLog**

Some usefull logs for your config and main databases.

You can activate auditlog overlay by using the following command:

```
    docker exec <OPENLDAP_CONTAINER> /docker-entrypoint.sh add_auditlog
```

All logs will be placed at /tmp. In this case, we recommend that you mount a volume into /tmp to avoid storagedriver overcharge and avoid data loss.

Replication Information
-----------------------

To prepare your environments to replication through syncrepl, you need to define the following envinroment variables:

 * LDAP_ID: LDAP RID of the current openldap instance. Numeric, normally something like 001, 002, etc;

With this variable defined, use the following command to prepare your openldap to replication:

```
    docker exec <OPENLDAP_CONTAINER> /docker-entrypoint.sh prepare_repl
```

After this, to link replication between openldap servers, submit ldif files with information about new servers as normal. LDIF Example (Adding a 2nd server, which address is myserver2.com):

idmapping.ldif
```
	dn: cn=config
	changetype: modify
	replace: olcServerID
	olcServerID: 001 ldap://myserver1.com/
	olcServerID: 002 ldap://myserver2.com/
```

syncreplconf.ldif
```
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcSyncrepl
olcSyncrepl: rid=001 provider=ldap://myserver1.com/ binddn="cn=admin,dc=example,dc=com
 " bindmethod=simple credentials=teste searchbase="dc=example,dc=com" type=ref
 reshAndPersist retry="5 5 300 5" timeout=1 rid=002 provider=ldap://myserver2.com/ bin
 ddn="cn=admin,dc=example,dc=com" bindmethod=simple credentials=teste searchba
 se="dc=example,dc=com" type=refreshAndPersist  retry="5 5 300 5" timeout=1
```

```
docker cp example.ldif <OPENLDAP_CONTAINER> /tmp/
docker exec <OPENLDAP_CONTAINER> ldapmodify -x -D cn=admin,cn=root -w ${LDAP_ADMIN_PASSWORD} -f /tmp/idmapping.ldif
docker exec <OPENLDAP_CONTAINER> ldapmodify -x -D cn=admin,cn=root -w ${LDAP_ADMIN_PASSWORD} -f /tmp/syncreplconf.ldif
```

Check the logs to verify if the replication is working. More information at:

https://www.openldap.org/doc/admin24/replication.html

K8s Considerations
------------------

If you need to use the image with Kubernetes, ensure to declare a pre-init container to use the `copy-to-volume.sh` script to copy openldap files into the target volume:

```
    spec:
      initContainers:
        - name: config-data
          image: gcavalcante8808/openldap
          command: ["/copy-ldap-data-to-volume.sh"]
          volumeMounts:
          - mountPath: /data
            name: ldap-conf
```

The volume used to hold the openldap data should mounted in the `/data` folder.

Changing Configurations
-----------------------

To change configurations from "cn=config" OLC, you need to use the DN "cn=admin,cn=config" with the same password provided in the LDAP_ADMIN_PASSWORD environment variable.

Author
------

Author: Gabriel Abdalla Cavalcante Silva (gabriel.cavalcante88@gmail.com)
