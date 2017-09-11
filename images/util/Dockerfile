FROM ibmjava

LABEL maintainer="Erin Schnabel <schnabel@us.ibm.com> (@ebullientworks)"

ENV ETCD_VERSION 2.2.2

RUN apt-get update \
  && apt-get install -y curl \
  \
# setup etcd
  && wget https://github.com/coreos/etcd/releases/download/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz -q \
  && tar xzf etcd-v${ETCD_VERSION}-linux-amd64.tar.gz etcd-v${ETCD_VERSION}-linux-amd64/etcdctl --strip-components=1 \
  && rm etcd-v${ETCD_VERSION}-linux-amd64.tar.gz \
  && mv etcdctl /usr/local/bin/etcdctl
