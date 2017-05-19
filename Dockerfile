FROM alpine
RUN apk add --no-cache openldap-clients openldap bash
COPY files/docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
