FROM gameontext/docker-liberty-custom:master-14

LABEL maintainer="Erin Schnabel <schnabel@us.ibm.com> (@ebullientworks)"

ENV SCALA_VERSION 2.12
ENV KAFKA_VERSION 0.10.2.1
ENV KAFKA_HOME /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}
ENV PATH="${KAFKA_HOME}/bin:${PATH}"
ENV TGZ=kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz

# Kafka client
RUN wget -q "http://apache.mirrors.spacedump.net/kafka/${KAFKA_VERSION}/${TGZ}" -O /tmp/${TGZ} \
 && tar xfz /tmp/${TGZ} -C /opt \
 && rm /tmp/${TGZ}

ADD https://raw.githubusercontent.com/gameontext/gameon/master/bin/init_couchdb.sh /init_couchdb.sh
COPY ./startup.sh /startup.sh

ENTRYPOINT []
CMD [ "/startup.sh" ]

HEALTHCHECK CMD test -f /initialized.txt
