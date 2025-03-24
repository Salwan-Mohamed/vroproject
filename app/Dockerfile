FROM tomcat:9.0-jdk11

LABEL maintainer="salwansaied"

# Remove default Tomcat applications
RUN rm -rf /usr/local/tomcat/webapps/*

# Configure application properties
COPY application.properties /usr/local/tomcat/application.properties

# Add application WAR file
COPY vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1
