# hynorvixx_psql_frotend

Flutter app (web-ready) for Hynorvixx backend.

## Deployment (EC2)

You can deploy the built Flutter web assets behind Nginx. Two options:

### Option A: Docker (Recommended)

1) Build web assets locally or in CI:

```
flutter build web --release --dart-define=API_BASE_URL=https://hynorvixx.com
```

2) Build and run container:

```
docker build -t hynorvixx-frontend:latest .
docker run -d --name hynorvixx-frontend -p 80:80 hynorvixx-frontend:latest
```

3) Put it behind your EC2 security group/ALB/NGINX TLS terminator as needed.

### Option B: Native Nginx on EC2

1) On EC2, install Nginx.

2) Build web assets on your machine or EC2:

```
flutter build web --release --dart-define=API_BASE_URL=https://hynorvixx.com
```

3) Copy `build/web/` to `/usr/share/nginx/html/`:

```
sudo rm -rf /usr/share/nginx/html/*
sudo cp -r build/web/* /usr/share/nginx/html/
```

4) Ensure Nginx config serves `index.html` fallback (example in `nginx.conf`).

5) Reload Nginx.

## CORS & HTTPS

- Frontend only calls `https://hynorvixx.com` using Authorization Bearer tokens.
- Ensure backend `.env` has your frontend origin in `CORS_ORIGIN`.

## Build Tips

- For different environments, override: `--dart-define=API_BASE_URL=...`
- Tokens are never logged; access token lives in-memory; refresh in SharedPreferences.
