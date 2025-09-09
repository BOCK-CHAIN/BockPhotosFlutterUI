# Simple runtime-only image to serve Flutter web build via Nginx
# Build your web assets first:
#   flutter build web --release --dart-define=API_BASE_URL=https://hynorvixx.com

FROM nginx:stable-alpine

COPY ./nginx.conf /etc/nginx/conf.d/default.conf
COPY ./build/web/ /usr/share/nginx/html/

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost/health || exit 0

CMD ["nginx", "-g", "daemon off;"]


