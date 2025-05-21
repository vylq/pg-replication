FROM postgres:15-alpine

COPY ./entrypoint.sh /usr/local/bin/docker-entrypoint-replica.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-replica.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint-replica.sh"]
