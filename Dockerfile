FROM ghcr.io/plankanban/planka:2.0.0-rc.4

USER root

RUN mkdir -p /app/private/attachments \
    && chown -R node:node /app/private

COPY start.sh /start.sh
RUN chmod +x /start.sh

ENTRYPOINT ["/start.sh"]
CMD ["node", "--max-old-space-size=128", "app.js"]
