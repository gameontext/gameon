#
# Based on a combination of: 
# https://github.com/colebrumley/docker-etcd/blob/master/Dockerfile, and
# https://github.com/efrecon/docker-etcd/blob/master/etcd/Dockerfile
#
FROM        alpine:3.2

# Note that etcd catches all variables that start with ETCD_ and possibly
# understands them as command-line arguments.  So we use a variable that does
# NOT start directly with ETCD to contain the version.
ENV __ETCD_VERSION 2.2.4

RUN apk --update add curl && \
        curl -sSL https://github.com/coreos/etcd/releases/download/v$__ETCD_VERSION/etcd-v$__ETCD_VERSION-linux-amd64.tar.gz | tar -zx -C /tmp -f - && \
        mv /tmp/etcd-v$__ETCD_VERSION-linux-amd64/etcd /usr/bin/etcd && \
        mv tmp/etcd-v$__ETCD_VERSION-linux-amd64/etcdctl /usr/bin/etcdctl && \
        rm -rf /tmp/etcd-v$__ETCD_VERSION-linux-amd64 && \
        mkdir /data && \
        mkdir /data.wal

EXPOSE      2379 2380 4001 7001

VOLUME /data

ADD         run.sh /bin/run.sh
ENTRYPOINT  ["/bin/run.sh"]
