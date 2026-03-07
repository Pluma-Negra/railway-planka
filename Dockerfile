FROM ghcr.io/plankanban/planka:2.0.3

USER root

RUN mkdir -p /app/data \
    && chown -R node:node /app/data

COPY start.sh /start.sh
RUN chmod +x /start.sh

ENTRYPOINT ["/start.sh"]
CMD ["node", "--max-old-space-size=128", "app.js"]
