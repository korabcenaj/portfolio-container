FROM nginxinc/nginx-unprivileged:1.29-alpine

COPY . /usr/share/nginx/html/
RUN mv /usr/share/nginx/html/portfolio.html /usr/share/nginx/html/index.html

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://127.0.0.1:8080/ || exit 1