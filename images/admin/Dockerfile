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


RUN apk --update add \
      bash \
      curl \
      python \
      python-dev \
      py-pip \
      build-base \
   && rm -rf /var/cache/apk/*

RUN pip install virtualenv \
  && pip install a8ctl==0.3 \
  && curl -sSL https://github.com/coreos/etcd/releases/download/v$__ETCD_VERSION/etcd-v$__ETCD_VERSION-linux-amd64.tar.gz | tar -zx -C /tmp -f - \
  && mv /tmp/etcd-v$__ETCD_VERSION-linux-amd64/etcd /usr/bin/etcd \
  && mv tmp/etcd-v$__ETCD_VERSION-linux-amd64/etcdctl /usr/bin/etcdctl \
  && rm -rf /tmp/etcd-v$__ETCD_VERSION-linux-amd64

COPY bin/etcdConfig.sh /usr/local/bin
COPY bin/a8sanity.sh /usr/local/bin
COPY bin/adminEnv.sh /etc/profile.d/

CMD [ "/usr/local/bin/etcdConfig.sh" ]
