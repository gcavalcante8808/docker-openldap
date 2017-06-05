FROM alpine
RUN apk add --no-cache openldap-clients openldap bash && \
    mkdir /docker-entrypoint-initdb.d/
COPY files/docker-entrypoint.sh /
COPY extra /extra
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["run_slapd"]
