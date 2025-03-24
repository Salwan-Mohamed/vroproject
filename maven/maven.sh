#!/bin/bash
# Maven Build and Docker Image Creation Script

# Exit script if any command fails
set -e

echo "Starting vProfile Project Build and Docker Images Creation"

# Clone the repository if not already present
if [ ! -d "vprofile-project" ]; then
  echo "Cloning vProfile project repository..."
  git clone -b main https://github.com/hkhcoder/vprofile-project.git
  cd vprofile-project
else
  echo "Repository already exists, pulling latest changes..."
  cd vprofile-project
  git pull
fi

# Update application.properties for containerized environment
echo "Updating application.properties for containerized environment..."
cat > src/main/resources/application.properties << 'EOL'
#JDBC Configutation for Database Connection
jdbc.driverClassName=com.mysql.jdbc.Driver
jdbc.url=jdbc:mysql://vprodb-service:3306/accounts?useUnicode=true&characterEncoding=UTF-8&zeroDateTimeBehavior=convertToNull
jdbc.username=${DB_USER}
jdbc.password=${DB_PASSWORD}

#Memcached Configuration For Active and StandBy Host
#For Active Host
memcached.active.host=vprocache-service
memcached.active.port=11211
#For StandBy Host
memcached.standBy.host=vprocache-service
memcached.standBy.port=11211

#RabbitMQ Configuration
rabbitmq.address=vpromq-service
rabbitmq.port=5672
rabbitmq.username=${RABBITMQ_USER}
rabbitmq.password=${RABBITMQ_PASSWORD}

#Elasticesearch Configuration
elasticsearch.host=vprosearch-service
elasticsearch.port=9300
elasticsearch.cluster=vprofile
elasticsearch.node=vprofilenode
EOL

# Maven build with detailed output
echo "Running Maven build..."
mvn clean package -DskipTests
echo "Maven build completed successfully!"

# Verify the WAR file was created
if [ -f "target/vprofile-v2.war" ]; then
  echo "WAR file successfully created at target/vprofile-v2.war"
  ls -lh target/vprofile-v2.war
else
  echo "ERROR: WAR file not created. Maven build may have failed."
  exit 1
fi

# Build MySQL Docker Image
echo "Building MySQL Docker image..."
cat > Dockerfile.db << 'EOL'
FROM mariadb:10.5

LABEL maintainer="salwansaied"

ENV MYSQL_ROOT_PASSWORD=admin123
ENV MYSQL_DATABASE=accounts
ENV MYSQL_USER=admin
ENV MYSQL_PASSWORD=admin123

COPY src/main/resources/db_backup.sql /docker-entrypoint-initdb.d/

EXPOSE 3306

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD mysqladmin ping -uroot -p${MYSQL_ROOT_PASSWORD} || exit 1
EOL

docker build -t salwansaied/vroproject:db -f Dockerfile.db .
echo "MySQL Docker image built successfully!"

# Build Memcached Docker Image
echo "Building Memcached Docker image..."
cat > Dockerfile.mc << 'EOL'
FROM memcached:1.6

LABEL maintainer="salwansaied"

# Configure memcached to listen on all interfaces
CMD ["memcached", "-m", "64", "-p", "11211", "-u", "memcache", "-l", "0.0.0.0"]

EXPOSE 11211

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD nc -z localhost 11211 || exit 1
EOL

docker build -t salwansaied/vroproject:mc -f Dockerfile.mc .
echo "Memcached Docker image built successfully!"

# Build RabbitMQ Docker Image
echo "Building RabbitMQ Docker image..."
cat > rabbitmq.conf << 'EOL'
loopback_users = none
listeners.tcp.default = 5672
management.tcp.port = 15672
EOL

cat > Dockerfile.rmq << 'EOL'
FROM rabbitmq:3.8-management

LABEL maintainer="salwansaied"

# Add RabbitMQ configuration
COPY rabbitmq.conf /etc/rabbitmq/
RUN chown rabbitmq:rabbitmq /etc/rabbitmq/rabbitmq.conf

# Create default user
RUN rabbitmq-plugins enable --offline rabbitmq_management && \
    echo '#!/bin/sh\n\
    rabbitmqctl wait --timeout 60 "$RABBITMQ_PID_FILE"\n\
    rabbitmqctl add_user test test 2>/dev/null\n\
    rabbitmqctl set_user_tags test administrator\n\
    rabbitmqctl set_permissions -p / test ".*" ".*" ".*"\n\
    echo "*** User test setup completed. ***"' > /usr/local/bin/setup-user.sh && \
    chmod +x /usr/local/bin/setup-user.sh

# Add setup-user.sh as a command to be executed when the container starts
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["rabbitmq-server"]

EXPOSE 5672 15672

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD rabbitmqctl status || exit 1
EOL

docker build -t salwansaied/vroproject:rmq -f Dockerfile.rmq .
echo "RabbitMQ Docker image built successfully!"

# Build Tomcat Docker Image
echo "Building Tomcat Docker image..."
cat > Dockerfile.app << 'EOL'
FROM tomcat:9.0-jdk11

LABEL maintainer="salwansaied"

# Remove default Tomcat applications
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy application WAR file
COPY target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1
EOL

docker build -t salwansaied/vroproject:app -f Dockerfile.app .
echo "Tomcat Docker image built successfully!"

# Build Nginx Docker Image
echo "Building Nginx Docker image..."
cat > vproapp.conf << 'EOL'
upstream vproapp {
    server vproapp-service:8080;
}

server {
    listen 80;
    
    location / {
        proxy_pass http://vproapp;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOL

cat > Dockerfile.web << 'EOL'
FROM nginx:1.22

LABEL maintainer="salwansaied"

# Remove default Nginx configuration
RUN rm -rf /etc/nginx/conf.d/*

# Add our Nginx config
COPY vproapp.conf /etc/nginx/conf.d/

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1
EOL

docker build -t salwansaied/vroproject:web -f Dockerfile.web .
echo "Nginx Docker image built successfully!"

echo "All Docker images have been built successfully!"
echo "You can now push them to Docker Hub with:"
echo "docker push salwansaied/vroproject:db"
echo "docker push salwansaied/vroproject:mc"
echo "docker push salwansaied/vroproject:rmq"
echo "docker push salwansaied/vroproject:app"
echo "docker push salwansaied/vroproject:web"
