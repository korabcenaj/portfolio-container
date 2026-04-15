FROM nginxinc/nginx-unprivileged:1.29-alpine

COPY portfolio.html /usr/share/nginx/html/index.html
COPY styles.css app.js projects.json projects.schema.json /usr/share/nginx/html/

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://127.0.0.1:8080/ || exit 1