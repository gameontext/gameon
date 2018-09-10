FROM gameontext/docker-liberty-custom:master-12

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
