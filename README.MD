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

Environment Variables
---------------------

The OpenLDAP image uses several environment variables which are easy to miss. While none of them is required,
they may significantly help you in the directory configuration task.

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

User Notes
----------

We plan to implement usefull features, like ldif reading during bootstraping, SSL Support and so On. Stay tunned in the github issues to more info.
Author
------

Author: Gabriel Abdalla Cavalcante Silva (gabriel.cavalcante88@gmail.com)
