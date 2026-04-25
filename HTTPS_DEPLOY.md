# HTTPS Production Deployment

Apartmann için HTTPS deployment kılavuzu. Tüm üç katman (API, Web, Flutter) HTTPS arkasında çalışacak şekilde hazırlanmıştır; bu rehber **reverse proxy ile TLS terminasyonu** modelini kullanır (en yaygın ve operasyonel kolay yöntem).

## Mimari

```
İnternet  ──HTTPS──►  Nginx/Caddy (TLS terminasyon)  ──HTTP──►  Kestrel
                       │                                  ▲
                       └─Let's Encrypt sertifikası        │
                                                          │
                                                  X-Forwarded-Proto: https
                                                  X-Forwarded-For: <client>
```

Reverse proxy (Nginx, Caddy veya Cloudflare Tunnel) HTTPS bağlantısını sonlandırır; uygulamaya HTTP olarak iletir, ancak `X-Forwarded-Proto` ve `X-Forwarded-For` header'larını ekler. Uygulama bu header'ları okuyarak gerçek scheme/IP'yi bilir.

## 1) Sunucu hazırlığı

```bash
# Ubuntu 22.04 / 24.04
sudo apt update
sudo apt install -y nginx postgresql certbot python3-certbot-nginx

# .NET 8 runtime
wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install -y aspnetcore-runtime-8.0
```

## 2) API + Web servislerini systemd ile çalıştır

`/etc/systemd/system/apartman-api.service`:
```ini
[Unit]
Description=ApartmanApp API
After=network.target postgresql.service

[Service]
WorkingDirectory=/var/www/apartman-api
ExecStart=/usr/bin/dotnet /var/www/apartman-api/ApartmanApp.API.dll
Restart=always
RestartSec=10
SyslogIdentifier=apartman-api
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://127.0.0.1:5255

[Install]
WantedBy=multi-user.target
```

`/etc/systemd/system/apartman-web.service`:
```ini
[Unit]
Description=ApartmanApp Web Panel
After=network.target apartman-api.service

[Service]
WorkingDirectory=/var/www/apartman-web
ExecStart=/usr/bin/dotnet /var/www/apartman-web/ApartmanWeb.dll
Restart=always
RestartSec=10
SyslogIdentifier=apartman-web
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://127.0.0.1:5256
Environment=ApiBaseUrl=http://127.0.0.1:5255

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now apartman-api apartman-web
```

## 3) Konfigürasyon dosyaları (gizli değerler)

`/var/www/apartman-api/appsettings.Production.json` (`chmod 600`, `chown www-data:www-data`):
```json
{
  "ConnectionStrings": {
    "Default": "Host=127.0.0.1;Port=5432;Database=apartman;Username=apartman;Password=GUCLU_PAROLA"
  },
  "Jwt": {
    "Key": "EN_AZ_64_KARAKTER_RANDOM_SECRET",
    "Issuer": "ApartmanAPI",
    "Audience": "ApartmanApp",
    "ExpiryMinutes": 480
  },
  "AdminSeed": {
    "Email": "admin@apartmann.example.com",
    "Sifre": "ILK_KURULUM_SONRASI_DEGISTIRIN",
    "ForcePasswordReset": false
  },
  "Cors": {
    "AllowedOrigins": [
      "https://panel.apartmann.example.com"
    ]
  }
}
```

> Gerçek JWT secret üretmek için: `openssl rand -base64 64`

## 4) Nginx reverse proxy

`/etc/nginx/sites-available/apartman`:
```nginx
# API → api.apartmann.example.com
server {
    listen 80;
    server_name api.apartmann.example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.apartmann.example.com;

    # Sertifikalar Certbot tarafından otomatik yerleştirilir
    ssl_certificate     /etc/letsencrypt/live/api.apartmann.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.apartmann.example.com/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    client_max_body_size 10M;  # foto upload için

    location / {
        proxy_pass         http://127.0.0.1:5255;
        proxy_http_version 1.1;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_set_header   Upgrade           $http_upgrade;
        proxy_set_header   Connection        keep-alive;
    }
}

# Web panel → panel.apartmann.example.com
server {
    listen 80;
    server_name panel.apartmann.example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name panel.apartmann.example.com;

    ssl_certificate     /etc/letsencrypt/live/panel.apartmann.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/panel.apartmann.example.com/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;

    location / {
        proxy_pass         http://127.0.0.1:5256;
        proxy_http_version 1.1;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/apartman /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 5) Let's Encrypt sertifikaları

```bash
sudo certbot --nginx -d api.apartmann.example.com -d panel.apartmann.example.com
# Sertifikalar 90 gün geçerli; certbot.timer otomatik yeniler
sudo systemctl enable --now certbot.timer
```

## 6) Flutter production build

```bash
cd ApartmanApp
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.apartmann.example.com
# veya iOS:
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://api.apartmann.example.com
```

`AndroidManifest.xml`'de `usesCleartextTraffic="false"` ayarı zaten var; production'da yanlışlıkla HTTP URL ile build edilirse uygulama çalışmaz.

## 7) Doğrulama

```bash
# API
curl -I https://api.apartmann.example.com/api/auth/login
# Beklenen header: HTTP/2 405  +  strict-transport-security: max-age=...

# Web
curl -I https://panel.apartmann.example.com/Account/Login
# Beklenen: HTTP/2 200 + strict-transport-security
```

API için `appsettings.json`'daki `Jwt:Key` değerinin **gerçekten 64+ karakter random** olduğundan emin olun:
```bash
sudo grep -c '.\{64,\}' /var/www/apartman-api/appsettings.Production.json
```

## 8) Operasyonel kontroller

- **DB backup**: `pg_dump` günlük cron + 7 günlük retention
- **Log rotasyonu**: `logs/api-*.log` zaten 14 günlük (Serilog ayarı). `/var/www/apartman-api/logs/` chown www-data
- **Firewall**: `ufw allow 22,80,443/tcp; ufw enable` — PostgreSQL (5432), API (5255), Web (5256) **dışarıdan erişilmesin**
- **Admin şifresi**: ilk login sonrası mutlaka değiştir; `AdminSeed:Sifre`'yi `appsettings.Production.json`'dan **kaldır**
- **PostgreSQL**: `pg_hba.conf`'da `local` + `127.0.0.1` haricindeki erişimi kapat

## Sorun giderme

| Belirti | Olası neden | Çözüm |
|---------|-------------|-------|
| `400 Bad Request` (Cookie) | Cookie `Secure=true` ama HTTP üzerinden istek geldi | Nginx'te `X-Forwarded-Proto: https` ayarlandığından emin ol |
| Flutter app `SocketException` | API_BASE_URL yanlış veya HTTPS sertifika hatası | Cihazdan `curl https://api...` ile test |
| HSTS sonrası geri dönülemez | HSTS 1 yıl önbellekleniyor | İlk deployment'tan emin olmadan `UseHsts()` aktif etme — gerekirse `MaxAge`'i kısalt |
| Login sonrası 401 sürekli | JWT secret değişti veya ortamlar arası key uyuşmuyor | `appsettings.Production.json`'da Issuer/Audience eşleştir |
