FROM nginx:1.22

LABEL maintainer="salwansaied"

# Remove default Nginx configuration
RUN rm -rf /etc/nginx/conf.d/*

# Add our Nginx config
COPY vproapp.conf /etc/nginx/conf.d/

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1
