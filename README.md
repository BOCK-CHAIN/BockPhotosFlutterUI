# hynorvixx_psql_frontend

**Flutter app (web-ready) for Hynorvixx backend**

---

## 🚀 Deployment on EC2

Deploy the built Flutter web assets behind Nginx.  
Choose your deployment method:

---

## 🐳 Option A: Docker (Recommended)

**1. Build web assets (locally or CI):**

flutter build web --release --dart-define=API_BASE_URL=https://hynorvixx.com


**2. Build and run Docker container:**

docker build -t hynorvixx-frontend:latest .
docker run -d --name hynorvixx-frontend -p 80:80 hynorvixx-frontend:latest


**3. (Optional) Place behind EC2 Security Group/ALB/Nginx TLS terminator as needed.**

---

## 🖥️ Option B: Native Nginx on EC2

**1. Install Nginx:**

sudo apt update
sudo apt install -y nginx


**2. Build web assets (locally or on EC2):**

flutter build web --release --dart-define=API_BASE_URL=https://hynorvixx.com

**3. Copy build output:**

sudo rm -rf /usr/share/nginx/html/*
sudo cp -r build/web/* /usr/share/nginx/html/


**4. Ensure Nginx config serves single-page app (index fallback):**  
Sample `/etc/nginx/sites-available/default`:

server {
    listen 80;
    server_name hynorvixx.com www.hynorvixx.com;

    root /var/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(?:css|js|jpg|jpeg|gif|png|ico|svg|woff2?)$ {
        expires 30d;
        add_header Cache-Control "public";
    }
}



**5. Reload Nginx:**

sudo nginx -t
sudo systemctl reload nginx


---

## 🔑 CORS & HTTPS

- Frontend only communicates with `https://hynorvixx.com` using Authorization Bearer tokens.
- Ensure backend `.env` includes your frontend domain in `CORS_ORIGIN`.

---

## 🛠️ Build Tips

- For different environments, use:

flutter build web --release --dart-define=API_BASE_URL=https://hynorvixx.com

- Tokens are never logged; access token is stored in-memory, refresh token in SharedPreferences.

---

**Your Flutter web frontend is now ready to deploy!**
