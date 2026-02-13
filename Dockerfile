FROM ghcr.io/plankanban/planka:2.0.0-rc.4

COPY start.sh /start.sh
RUN chmod +x /start.sh

# ENTRYPOINT:
ENTRYPOINT ["/start.sh"]
