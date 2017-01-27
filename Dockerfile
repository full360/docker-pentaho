FROM openjdk:8-jre-alpine
MAINTAINER Jonathan DeMarks
# Based on work done by Wellington Marinho (https://github.com/wmarinho/docker-pentaho)
# Note: Really, really requires Postgres 9.5, any higher version will break without an updated driver (in commented section below).

ENV MAJOR_VERSION 7.0
ENV MINOR_VERSION 7.0.0.0-25
ENV PENTAHO_HOME /opt/pentaho
ENV PENTAHO_JAVA_HOME $JAVA_HOME
ENV PENTAHO_SERVER ${PENTAHO_HOME}/server/pentaho-server

# Get minimum requirements to install
RUN apk add --update wget unzip bash

# Setup pentaho user
RUN mkdir -p ${PENTAHO_HOME}/server; mkdir ${PENTAHO_HOME}/.pentaho; adduser -D -s /bin/sh -h ${PENTAHO_HOME} pentaho; chown -R pentaho:pentaho ${PENTAHO_HOME}
USER pentaho
WORKDIR ${PENTAHO_HOME}/server

# Get Pentaho Server
RUN echo http://downloads.sourceforge.net/project/pentaho/Business%20Intelligence%20Server/${MAJOR_VERSION}/pentaho-server-ce-${MINOR_VERSION}.zip | xargs wget -qO- -O tmp.zip && \
    unzip -q tmp.zip -d ${PENTAHO_HOME}/server && \
    rm -f tmp.zip

# Get MS SQL JDBC driver
RUN echo https://download.microsoft.com/download/0/2/A/02AAE597-3865-456C-AE7F-613F99F850A8/enu/sqljdbc_6.0.8112.100_enu.tar.gz | xargs wget -qO- -O tmp.tar.gz && \
    tar -zxf tmp.tar.gz && \
	rm -f tmp.tar.gz && \
	cp sqljdbc_6.0/enu/jre8/sqljdbc42.jar ${PENTAHO_SERVER}/tomcat/lib/ && \
	rm -fr sqljdbc_6.0

# Replace outdated Postgresql JDBC driver
#RUN rm ${PENTAHO_SERVER}/tomcat/lib/postgresql-9.3-1102-jdbc4.jar && \
#    echo https://jdbc.postgresql.org/download/postgresql-9.4.1212.jar | xargs wget -qO- -O ${PENTAHO_SERVER}/tomcat/lib/postgresql-9.4.1212.jar

ENV CATALINA_OPTS="-Djava.awt.headless=true -Xms4096m -Xmx6144m -XX:MaxPermSize=256m -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000"

# Disable first-time startup prompt
RUN rm ${PENTAHO_SERVER}/promptuser.sh

# Disable daemon mode for Tomcat
RUN sed -i -e 's/\(exec ".*"\) start/\1 run/' ${PENTAHO_SERVER}/tomcat/bin/startup.sh

#
# Begin - root area for system work
#       - Put any customizations here that need to be done as root (sql client installs, etc)
#
USER root

RUN apk add postgresql-client

USER pentaho
#
# End  - root area for system work
#

COPY scripts ${PENTAHO_HOME}/scripts
COPY config ${PENTAHO_HOME}/config

EXPOSE 8080
ENTRYPOINT ["sh", "-c", "$PENTAHO_HOME/scripts/run.sh"]