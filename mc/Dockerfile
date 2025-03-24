FROM memcached:1.6

LABEL maintainer="salwansaied"

# Configure memcached to listen on all interfaces
CMD ["memcached", "-m", "64", "-p", "11211", "-u", "memcache", "-l", "0.0.0.0"]

EXPOSE 11211

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD nc -z localhost 11211 || exit 1
