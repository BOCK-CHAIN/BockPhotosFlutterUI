# hynorvixx_psql_frontend

**Flutter app (web-ready) for Hynorvixx backend**

---

## 🚀 Deployment on EC2

Deploy the built Flutter web assets behind Nginx.  

---

**1. Build frontend locally:**
```
flutter build web --release --dart-define=API_BASE_URL=https://hynorvixx.com
```
This creates build/web/ folder.


**2. Copy build artifacts to EC2:**
```
scp -i C:\path\to\key.pem -r build/web/* ubuntu@EC2_PUBLIC_IP:~/hynorvixx-build
```


**3. Install Nginx on EC2:**

SSH into your instance:
```
ssh -i C:\path\to\key.pem ubuntu@EC2_PUBLIC_IP
```
Install:

```
sudo apt update
sudo apt install -y nginx
sudo systemctl enable --now nginx
```


**4. Deploy Flutter build to Nginx root:**  

On EC2:
```
sudo rm -rf /var/www/html/*
sudo cp -r ~/hynorvixx-build/* /var/www/html/
```

**5. Configure Nginx for SPA (index.html fallback):**  

Edit default site config:
```
sudo nano /etc/nginx/sites-available/default
```

Replace the server { ... } block with:
```
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
```

**6. Reload Nginx:**
```
sudo nginx -t
sudo systemctl reload nginx
```


---

## 🔑 CORS & HTTPS

- Frontend only communicates with `https://hynorvixx.com` using Authorization Bearer tokens.
- Ensure backend `.env` includes your frontend domain in `CORS_ORIGIN`.

---

## 🛠️ Build Tips

- For different environments, use:
```
flutter build web --release --dart-define=API_BASE_URL=https://hynorvixx.com
```

- Tokens are never logged; access token is stored in-memory, refresh token in SharedPreferences.

---

**Your Flutter web frontend is now ready to deploy!**

## Want to contribute?

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License.
