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
