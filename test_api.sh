#!/bin/bash
# ============================================================
# ApartmanApp API — Kapsamlı Test Script
# ============================================================
BASE="http://localhost:5255"
PASS=0; FAIL=0; WARN=0

CGREEN='\033[0;32m'; CRED='\033[0;31m'; CYELLOW='\033[1;33m'
CCYAN='\033[0;36m'; CBOLD='\033[1m'; CNC='\033[0m'

section() { echo -e "\n${CCYAN}${CBOLD}══════ $1 ══════${CNC}"; }
ok()      { echo -e "  ${CGREEN}✓ PASS${CNC} $1"; ((PASS++)); }
fail()    { echo -e "  ${CRED}✗ FAIL${CNC} $1"; ((FAIL++)); }
warn()    { echo -e "  ${CYELLOW}⚠ WARN${CNC} $1"; ((WARN++)); }

# HTTP isteği at — BODY__STATUS__NNN formatında döndürür
req() {
  local method=$1 url=$2 data=$3 token=$4
  local args=(-s -w "__STATUS__%{http_code}" -X "$method" -H "Content-Type: application/json")
  [[ -n "$token" ]] && args+=(-H "Authorization: Bearer $token")
  [[ -n "$data"  ]] && args+=(-d "$data")
  curl "${args[@]}" "$url"
}

# Status code ayıkla
sc()   { echo "$1" | sed 's/.*__STATUS__//' ; }
# Body ayıkla
body() { echo "$1" | sed 's/__STATUS__[0-9]*$//' ; }

# JSON'dan string değer al: "key":"value"
jstr() { body "$1" | sed 's/.*"'"$2"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'; }
# JSON'dan number değer al: "key":N
jnum() { body "$1" | sed 's/.*"'"$2"'"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/'; }
# JSON'dan bool al: "key":true/false
jbool() { body "$1" | sed 's/.*"'"$2"'"[[:space:]]*:[[:space:]]*\(true\|false\).*/\1/'; }
# "id":N — ilk olanı döndür
first_id() { body "$1" | grep -o '"id"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | grep -o '[0-9]*$'; }
# data içindeki ilk id
data_id()  { body "$1" | sed 's/.*"id"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/'; }
# id sayısı (kayıt sayısı tahmini)
count_ids() { body "$1" | grep -o '"id"[[:space:]]*:[[:space:]]*[0-9]*' | wc -l | tr -d ' '; }
# token (uzun base64 string)
get_token() { body "$1" | grep -o '"token"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'; }

# ============================================================
section "1. AUTH — Login"
# ============================================================

# 1.1 Admin girişi
R=$(req POST "$BASE/api/auth/login" '{"email":"admin@apartman.com","sifre":"Test123!"}')
SC=$(sc "$R"); ADMIN_TOKEN=$(get_token "$R")
B=$(body "$R")
ADMIN_ID=$(echo "$B" | grep -o '"id"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | grep -o '[0-9]*$')
if [[ "$SC" == "200" && -n "$ADMIN_TOKEN" ]]; then
  ok "Admin girişi → 200, token alındı (userId=$ADMIN_ID)"
else
  fail "Admin girişi → HTTP $SC | token boş mu: $([ -z "$ADMIN_TOKEN" ] && echo evet || echo hayır)"
fi

# 1.2 Sakin girişi
R=$(req POST "$BASE/api/auth/login" '{"email":"sakin@apartman.com","sifre":"Test123!"}')
SC=$(sc "$R"); SAKIN_TOKEN=$(get_token "$R")
B=$(body "$R")
SAKIN_ID=$(echo "$B" | grep -o '"id"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | grep -o '[0-9]*$')
if [[ "$SC" == "200" && -n "$SAKIN_TOKEN" ]]; then
  ok "Sakin girişi → 200, token alındı (userId=$SAKIN_ID)"
else
  fail "Sakin girişi → HTTP $SC"
fi

# 1.3 Yanlış şifre → 401
R=$(req POST "$BASE/api/auth/login" '{"email":"admin@apartman.com","sifre":"yanlis123"}')
SC=$(sc "$R")
[[ "$SC" == "401" ]] && ok "Yanlış şifre → 401" || fail "Yanlış şifre → HTTP $SC (401 beklendi)"

# 1.4 Boş kimlik → 400
R=$(req POST "$BASE/api/auth/login" '{"email":"","sifre":""}')
SC=$(sc "$R")
[[ "$SC" == "400" ]] && ok "Boş kimlik → 400" || fail "Boş kimlik → HTTP $SC (400 beklendi)"

# 1.5 Token olmadan korumalı endpoint → 401
R=$(req GET "$BASE/api/kullanici")
SC=$(sc "$R")
[[ "$SC" == "401" ]] && ok "Token olmadan korumalı endpoint → 401" || fail "Token olmadan → HTTP $SC (401 beklendi)"

# ============================================================
section "2. KULLANICI — CRUD"
# ============================================================

# 2.1 Admin tüm kullanıcıları görebilir
R=$(req GET "$BASE/api/kullanici" "" "$ADMIN_TOKEN")
SC=$(sc "$R"); COUNT=$(count_ids "$R")
[[ "$SC" == "200" ]] && ok "Kullanıcı listesi → 200, yakl. $COUNT kayıt" || fail "Kullanıcı listesi → HTTP $SC"

# 2.2 Sakin kullanıcı listesini çekemez → 403
R=$(req GET "$BASE/api/kullanici" "" "$SAKIN_TOKEN")
SC=$(sc "$R")
[[ "$SC" == "403" ]] && ok "Sakin kullanıcı listesini çekemez → 403" || fail "Sakin listesi → HTTP $SC (403 beklendi)"

# 2.3 /me endpoint
R=$(req GET "$BASE/api/kullanici/me" "" "$ADMIN_TOKEN")
SC=$(sc "$R")
ME_ID=$(first_id "$R")
if [[ "$SC" == "200" && "$ME_ID" == "$ADMIN_ID" ]]; then
  ok "GET /me → 200 (id=$ME_ID eşleşti)"
else
  fail "GET /me → HTTP $SC, id=$ME_ID (beklenen $ADMIN_ID)"
fi

# 2.4 Yeni kullanıcı oluştur
STAMP=$(date +%s)
NEW_EMAIL="testuser_${STAMP}@test.com"
R=$(req POST "$BASE/api/kullanici" \
  "{\"ad\":\"TestAd\",\"soyad\":\"TestSoyad\",\"email\":\"$NEW_EMAIL\",\"rol\":1,\"daireNo\":\"99\",\"sifre\":\"Test123!\"}" \
  "$ADMIN_TOKEN")
SC=$(sc "$R")
NEW_USER_ID=$(first_id "$R")
if [[ "$SC" == "201" && -n "$NEW_USER_ID" ]]; then
  ok "Kullanıcı oluştur → 201 (id=$NEW_USER_ID)"
else
  fail "Kullanıcı oluştur → HTTP $SC | $(body "$R" | head -c 120)"
fi

# 2.5 Duplicate email → 400
R=$(req POST "$BASE/api/kullanici" \
  "{\"ad\":\"Dup\",\"soyad\":\"Dup\",\"email\":\"$NEW_EMAIL\",\"rol\":1,\"daireNo\":\"100\",\"sifre\":\"Test123!\"}" \
  "$ADMIN_TOKEN")
SC=$(sc "$R")
[[ "$SC" == "400" ]] && ok "Duplicate email → 400" || warn "Duplicate email → HTTP $SC (400 beklendi)"

# 2.6 Kullanıcı güncelle
if [[ -n "$NEW_USER_ID" ]]; then
  R=$(req PUT "$BASE/api/kullanici/$NEW_USER_ID" \
    "{\"ad\":\"Guncellendi\",\"soyad\":\"TestSoyad\",\"email\":\"$NEW_EMAIL\",\"daireNo\":\"99\"}" \
    "$ADMIN_TOKEN")
  SC=$(sc "$R")
  [[ "$SC" == "200" ]] && ok "Kullanıcı güncelle → 200" || fail "Kullanıcı güncelle → HTTP $SC | $(body "$R" | head -c 120)"

  # 2.7 Güncelleme yansıdı mı?
  R=$(req GET "$BASE/api/kullanici/$NEW_USER_ID" "" "$ADMIN_TOKEN")
  SC=$(sc "$R")
  # adSoyad field'ı "Guncellendi TestSoyad" içermeli
  ADSOYAD=$(body "$R" | grep -o '"adSoyad"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/')
  if [[ "$SC" == "200" && "$ADSOYAD" == *"Guncellendi"* ]]; then
    ok "Kullanıcı getir → güncelleme yansıdı (adSoyad='$ADSOYAD')"
  else
    fail "Kullanıcı getir → HTTP $SC, adSoyad='$ADSOYAD' ('Guncellendi' beklendi)"
  fi
fi

# 2.8 Geçersiz id → 404
R=$(req GET "$BASE/api/kullanici/99999" "" "$ADMIN_TOKEN")
SC=$(sc "$R")
[[ "$SC" == "404" ]] && ok "Geçersiz kullanıcı id → 404" || fail "Geçersiz id → HTTP $SC (404 beklendi)"

# 2.9 FCM token kaydet
if [[ -n "$SAKIN_ID" ]]; then
  R=$(req PUT "$BASE/api/kullanici/$SAKIN_ID/fcm-token" '{"token":"fcm_test_token_abc"}' "$SAKIN_TOKEN")
  SC=$(sc "$R")
  [[ "$SC" == "200" ]] && ok "FCM token kaydet → 200" || fail "FCM token → HTTP $SC"
fi

# ============================================================
section "3. ARIZA — CRUD"
# ============================================================

# 3.1 Arıza listesi
R=$(req GET "$BASE/api/ariza" "" "$ADMIN_TOKEN")
SC=$(sc "$R"); COUNT=$(count_ids "$R")
[[ "$SC" == "200" ]] && ok "Arıza listesi → 200, yakl. $COUNT kayıt" || fail "Arıza listesi → HTTP $SC"

# 3.2 Arıza oluştur (oncelik: integer — ASCII data)
R=$(req POST "$BASE/api/ariza" \
  "{\"baslik\":\"Kapi Kilidi Bozuk\",\"aciklama\":\"Kapi kilit sorunu\",\"oncelik\":1,\"bildirenId\":$SAKIN_ID}" \
  "$SAKIN_TOKEN")
SC=$(sc "$R")
ARIZA_ID=$(first_id "$R")
if [[ "$SC" == "201" && -n "$ARIZA_ID" ]]; then
  ok "Arıza oluştur (int enum) → 201 (id=$ARIZA_ID)"
else
  fail "Arıza oluştur → HTTP $SC | $(body "$R" | head -c 200)"
fi

# 3.3 Arıza oluştur (oncelik: string enum — ASCII only)
R=$(req POST "$BASE/api/ariza" \
  "{\"baslik\":\"Asansor Arizasi\",\"aciklama\":\"Asansor calisiyor\",\"oncelik\":\"Yuksek\",\"bildirenId\":$SAKIN_ID}" \
  "$SAKIN_TOKEN")
SC=$(sc "$R")
ARIZA_ID2=$(first_id "$R")
if [[ "$SC" == "201" && -n "$ARIZA_ID2" ]]; then
  ok "Arıza oluştur (string enum) → 201 (id=$ARIZA_ID2)"
else
  warn "Arıza oluştur (string enum) → HTTP $SC — string enum kabul edilmiyor"
fi

# 3.4 Validasyon: boş başlık → 400
R=$(req POST "$BASE/api/ariza" \
  "{\"baslik\":\"\",\"aciklama\":\"x\",\"oncelik\":1,\"bildirenId\":$SAKIN_ID}" \
  "$SAKIN_TOKEN")
SC=$(sc "$R")
[[ "$SC" == "400" ]] && ok "Boş başlık → 400" || fail "Boş başlık → HTTP $SC (400 beklendi)"

# 3.5 Arıza detayı
if [[ -n "$ARIZA_ID" ]]; then
  R=$(req GET "$BASE/api/ariza/$ARIZA_ID" "" "$ADMIN_TOKEN")
  SC=$(sc "$R")
  BASLIK=$(body "$R" | grep -o '"baslik"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
  DURUM=$(jstr "$R" "durum")
  if [[ "$SC" == "200" && "$BASLIK" == "Kapi Kilidi Bozuk" ]]; then
    ok "Arıza detay → 200 (başlık=$BASLIK, durum=$DURUM)"
  else
    fail "Arıza detay → HTTP $SC, başlık='$BASLIK' (Kapi Kilidi Bozuk beklendi)"
  fi

  # 3.6 Durum güncelle: Inceleniyor (1)
  R=$(req PATCH "$BASE/api/ariza/$ARIZA_ID/durum" '{"durum":1}' "$ADMIN_TOKEN")
  SC=$(sc "$R")
  [[ "$SC" == "200" ]] && ok "Durum → Inceleniyor (1) → 200" || fail "Durum → 1 → HTTP $SC"

  # 3.7 Durum güncelle: Tamamlandi (2)
  R=$(req PATCH "$BASE/api/ariza/$ARIZA_ID/durum" '{"durum":2}' "$ADMIN_TOKEN")
  SC=$(sc "$R")
  [[ "$SC" == "200" ]] && ok "Durum → Tamamlandi (2) → 200" || fail "Durum → 2 → HTTP $SC"

  # 3.8 Durum güncelle: Reddedildi (3) + redNedeni
  R=$(req PATCH "$BASE/api/ariza/$ARIZA_ID/durum" '{"durum":3,"redNedeni":"Tekrar eden sorun"}' "$ADMIN_TOKEN")
  SC=$(sc "$R")
  RED=$(jstr "$R" "redNedeni")
  if [[ "$SC" == "200" ]]; then
    ok "Durum → Reddedildi (3) → 200 (redNedeni='$RED')"
  else
    fail "Durum → Reddedildi → HTTP $SC | $(body "$R" | head -c 150)"
  fi
fi

# 3.9 Blok filtresi
R=$(req GET "$BASE/api/ariza?blokNo=A" "" "$ADMIN_TOKEN")
SC=$(sc "$R")
[[ "$SC" == "200" ]] && ok "Arıza ?blokNo=A filtresi → 200" || fail "Blok filtresi → HTTP $SC"

# 3.10 Geçersiz arıza id → 404
R=$(req GET "$BASE/api/ariza/99999" "" "$ADMIN_TOKEN")
SC=$(sc "$R")
[[ "$SC" == "404" ]] && ok "Geçersiz arıza id → 404" || fail "Geçersiz arıza → HTTP $SC (404 beklendi)"

# ============================================================
section "4. ARIZA TAKİP"
# ============================================================

# Takip için yeni arıza
R=$(req POST "$BASE/api/ariza" \
  "{\"baslik\":\"Takip Testi\",\"aciklama\":\"takip icin\",\"oncelik\":0,\"bildirenId\":$SAKIN_ID}" \
  "$SAKIN_TOKEN")
SC=$(sc "$R")
TAKIP_ARIZA_ID=$(first_id "$R")

if [[ "$SC" == "201" && -n "$TAKIP_ARIZA_ID" ]]; then
  # 4.1 Admin takip etsin
  R=$(req POST "$BASE/api/ariza/$TAKIP_ARIZA_ID/takip" "" "$ADMIN_TOKEN")
  SC=$(sc "$R")
  [[ "$SC" == "200" ]] && ok "Admin arıza takip et → 200" || fail "Takip et → HTTP $SC | $(body "$R" | head -c 100)"

  # 4.2 Takip durumu kontrol
  R=$(req GET "$BASE/api/ariza/$TAKIP_ARIZA_ID/takip-durumu" "" "$ADMIN_TOKEN")
  SC=$(sc "$R")
  TAKIP_EDIYOR=$(jbool "$R" "takipEdiyor")
  TAKIPCI=$(jnum "$R" "takipciSayisi")
  if [[ "$SC" == "200" && "$TAKIP_EDIYOR" == "true" ]]; then
    ok "Takip durumu → takipEdiyor=true, takipçiSayisi=$TAKIPCI"
  else
    fail "Takip durumu → HTTP $SC, takipEdiyor=$TAKIP_EDIYOR | $(body "$R")"
  fi

  # 4.3 Sakin de takip etsin
  R=$(req POST "$BASE/api/ariza/$TAKIP_ARIZA_ID/takip" "" "$SAKIN_TOKEN")
  SC=$(sc "$R")
  [[ "$SC" == "200" ]] && ok "Sakin de takip et → 200" || warn "Sakin takip et → HTTP $SC"

  # 4.4 Takipçi sayısı 2+
  R=$(req GET "$BASE/api/ariza/$TAKIP_ARIZA_ID/takip-durumu" "" "$ADMIN_TOKEN")
  SC=$(sc "$R")
  TAKIPCI2=$(jnum "$R" "takipciSayisi")
  if [[ "$SC" == "200" && "$TAKIPCI2" -ge 2 ]] 2>/dev/null; then
    ok "Takipçi sayısı = $TAKIPCI2 (2+ beklendi)"
  else
    warn "Takipçi sayısı = $TAKIPCI2 (2 beklendi)"
  fi

  # 4.5 Takipten çık
  R=$(req DELETE "$BASE/api/ariza/$TAKIP_ARIZA_ID/takip" "" "$ADMIN_TOKEN")
  SC=$(sc "$R")
  [[ "$SC" == "200" ]] && ok "Takipten çık → 200" || fail "Takipten çık → HTTP $SC"

  # 4.6 Tekrar takipten çık → 404
  R=$(req DELETE "$BASE/api/ariza/$TAKIP_ARIZA_ID/takip" "" "$ADMIN_TOKEN")
  SC=$(sc "$R")
  [[ "$SC" == "404" ]] && ok "Tekrar takipten çık → 404 (doğru)" || warn "Tekrar takipten çık → HTTP $SC (404 beklendi)"
else
  warn "Takip arızası oluşturulamadı → takip testleri atlandı"
fi

# ============================================================
section "5. AİDAT — CRUD"
# ============================================================

# 5.1 Aidat oluştur
TEST_AY=$((RANDOM % 12 + 1)); TEST_YIL=2030
R=$(req POST "$BASE/api/aidat" \
  "{\"kullaniciId\":$SAKIN_ID,\"tutar\":500.00,\"ay\":$TEST_AY,\"yil\":$TEST_YIL}" \
  "$ADMIN_TOKEN")
SC=$(sc "$R")
AIDAT_ID=$(first_id "$R")
if [[ "$SC" == "201" && -n "$AIDAT_ID" ]]; then
  ok "Aidat oluştur → 201 (id=$AIDAT_ID)"
else
  fail "Aidat oluştur → HTTP $SC | $(body "$R" | head -c 150)"
fi

# 5.2 Tüm aidatlar (admin)
R=$(req GET "$BASE/api/aidat" "" "$ADMIN_TOKEN")
SC=$(sc "$R"); COUNT=$(count_ids "$R")
[[ "$SC" == "200" ]] && ok "Aidat listesi → 200, yakl. $COUNT kayıt" || fail "Aidat listesi → HTTP $SC"

# 5.3 Sakin tüm aidatları çekemez → 403
R=$(req GET "$BASE/api/aidat" "" "$SAKIN_TOKEN")
SC=$(sc "$R")
[[ "$SC" == "403" ]] && ok "Sakin aidat listesini çekemez → 403" || warn "Sakin aidat listesi → HTTP $SC (403 beklendi)"

# 5.4 Kullanıcıya göre aidatlar
R=$(req GET "$BASE/api/aidat/kullanici/$SAKIN_ID" "" "$SAKIN_TOKEN")
SC=$(sc "$R"); COUNT=$(count_ids "$R")
[[ "$SC" == "200" ]] && ok "Kullanıcı aidatları → 200, $COUNT kayıt" || fail "Kullanıcı aidatları → HTTP $SC"

# 5.5 Aidat by id
if [[ -n "$AIDAT_ID" ]]; then
  R=$(req GET "$BASE/api/aidat/$AIDAT_ID" "" "$ADMIN_TOKEN")
  SC=$(sc "$R")
  TUTAR=$(jnum "$R" "tutar")
  if [[ "$SC" == "200" ]]; then
    ok "Aidat detay → 200 (tutar=$TUTAR)"
  else
    fail "Aidat detay → HTTP $SC"
  fi

  # 5.6 Ödeme durumu → Odendi
  R=$(req PATCH "$BASE/api/aidat/$AIDAT_ID/odemeDurumu" '{"odemeDurumu":"Odendi"}' "$ADMIN_TOKEN")
  SC=$(sc "$R")
  DURUM=$(jstr "$R" "odemeDurumu")
  [[ "$SC" == "200" ]] && ok "Aidat ödeme → Odendi → 200 (durum=$DURUM)" || fail "Aidat ödeme → HTTP $SC"

  # 5.7 Ödeme durumu → Gecikti
  R=$(req PATCH "$BASE/api/aidat/$AIDAT_ID/odemeDurumu" '{"odemeDurumu":"Gecikti"}' "$ADMIN_TOKEN")
  SC=$(sc "$R")
  [[ "$SC" == "200" ]] && ok "Aidat ödeme → Gecikti → 200" || fail "Aidat Gecikti → HTTP $SC"
fi

# 5.8 Geçersiz aidat id → 404
R=$(req GET "$BASE/api/aidat/99999" "" "$ADMIN_TOKEN")
SC=$(sc "$R")
[[ "$SC" == "404" ]] && ok "Geçersiz aidat id → 404" || fail "Geçersiz aidat → HTTP $SC (404 beklendi)"

# ============================================================
section "6. OTOMATİK AİDAT"
# ============================================================

# 6.1 Upsert
R=$(req POST "$BASE/api/otomatik-aidat" \
  "{\"kullaniciId\":$SAKIN_ID,\"tutar\":750.00,\"aktif\":true}" \
  "$ADMIN_TOKEN")
SC=$(sc "$R")
OA_ID=$(first_id "$R")
if [[ "$SC" == "200" && -n "$OA_ID" ]]; then
  ok "Otomatik aidat upsert → 200 (id=$OA_ID)"
else
  fail "Otomatik aidat upsert → HTTP $SC | $(body "$R" | head -c 150)"
fi

# 6.2 Liste
R=$(req GET "$BASE/api/otomatik-aidat" "" "$ADMIN_TOKEN")
SC=$(sc "$R"); COUNT=$(count_ids "$R")
[[ "$SC" == "200" ]] && ok "Otomatik aidat listesi → 200, $COUNT kayıt" || fail "Otomatik aidat listesi → HTTP $SC"

# 6.3 Sakin erişemez → 403
R=$(req GET "$BASE/api/otomatik-aidat" "" "$SAKIN_TOKEN")
SC=$(sc "$R")
[[ "$SC" == "403" ]] && ok "Sakin otomatik aidatlara erişemez → 403" || warn "Sakin OA → HTTP $SC (403 beklendi)"

# 6.4 Toggle
if [[ -n "$OA_ID" ]]; then
  R=$(req PATCH "$BASE/api/otomatik-aidat/$OA_ID/toggle" "" "$ADMIN_TOKEN")
  SC=$(sc "$R")
  AKTIF=$(body "$R" | grep -o '"aktifMi"[[:space:]]*:[[:space:]]*[a-z]*' | sed 's/.*:[[:space:]]*//')
  [[ "$SC" == "200" ]] && ok "Otomatik aidat toggle → aktifMi=$AKTIF" || fail "OA toggle → HTTP $SC"

  # 6.5 Tutar güncelle
  R=$(req PATCH "$BASE/api/otomatik-aidat/$OA_ID/tutar" '{"tutar":1000}' "$ADMIN_TOKEN")
  SC=$(sc "$R")
  YENI_T=$(jnum "$R" "tutar")
  [[ "$SC" == "200" ]] && ok "Otomatik aidat tutar güncelle → 200 (tutar=$YENI_T)" || fail "OA tutar → HTTP $SC"
fi

# 6.6 Manuel üretim
R=$(req POST "$BASE/api/otomatik-aidat/uret" '{"ay":6,"yil":2026}' "$ADMIN_TOKEN")
SC=$(sc "$R")
URETILEN=$(jnum "$R" "uretilen")
[[ "$SC" == "200" ]] && ok "Otomatik aidat üretim → 200 ($URETILEN kayıt üretildi)" || fail "OA üretim → HTTP $SC | $(body "$R")"

# ============================================================
section "7. BİLDİRİM"
# ============================================================

# 7.1 Bildirimler (sakin)
R=$(req GET "$BASE/api/bildirim" "" "$SAKIN_TOKEN")
SC=$(sc "$R"); COUNT=$(count_ids "$R")
[[ "$SC" == "200" ]] && ok "Bildirim listesi → 200, $COUNT bildirim" || fail "Bildirim listesi → HTTP $SC"

# 7.2 Okunmamış sayı
R=$(req GET "$BASE/api/bildirim/okunmamis-sayi" "" "$SAKIN_TOKEN")
SC=$(sc "$R")
UNREAD=$(jnum "$R" "count")
[[ "$SC" == "200" ]] && ok "Okunmamış bildirim sayısı → 200, count=$UNREAD" || fail "Okunmamış sayı → HTTP $SC"

# 7.3 Duyuru gönder (admin)
R=$(req POST "$BASE/api/bildirim/duyuru" \
  '{"baslik":"Test Duyurusu","icerik":"Bu bir test duyurusudur."}' \
  "$ADMIN_TOKEN")
SC=$(sc "$R")
[[ "$SC" == "200" ]] && ok "Duyuru gönder → 200" || fail "Duyuru gönder → HTTP $SC | $(body "$R" | head -c 100)"

# 7.4 Daire bildirimi (ASCII icerik)
R=$(req POST "$BASE/api/bildirim/daire" \
  '{"daireNo":"99","baslik":"Daire Test","icerik":"Test mesaji"}' \
  "$ADMIN_TOKEN")
SC=$(sc "$R")
[[ "$SC" == "200" ]] && ok "Daire bildirimi → 200" || fail "Daire bildirimi → HTTP $SC | $(body "$R" | head -c 100)"

# 7.5 Boş duyuru → 400
R=$(req POST "$BASE/api/bildirim/duyuru" '{"baslik":"","icerik":""}' "$ADMIN_TOKEN")
SC=$(sc "$R")
[[ "$SC" == "400" ]] && ok "Boş duyuru → 400" || fail "Boş duyuru → HTTP $SC (400 beklendi)"

# 7.6 Sakin duyuru gönderemez → 403
R=$(req POST "$BASE/api/bildirim/duyuru" '{"baslik":"x","icerik":"y"}' "$SAKIN_TOKEN")
SC=$(sc "$R")
[[ "$SC" == "403" ]] && ok "Sakin duyuru gönderemez → 403" || fail "Sakin duyuru → HTTP $SC (403 beklendi)"

# 7.7 Bildirim okundu işaretle
R=$(req GET "$BASE/api/bildirim" "" "$SAKIN_TOKEN")
BID=$(first_id "$R")
if [[ -n "$BID" ]]; then
  R=$(req PATCH "$BASE/api/bildirim/$BID/okundu" "" "$SAKIN_TOKEN")
  SC=$(sc "$R")
  [[ "$SC" == "200" ]] && ok "Bildirim okundu → 200 (id=$BID)" || fail "Bildirim okundu → HTTP $SC"
else
  warn "Okundu testi → bildirim yok (atlandı)"
fi

# 7.8 Geçersiz bildirim id → 404
R=$(req PATCH "$BASE/api/bildirim/99999/okundu" "" "$SAKIN_TOKEN")
SC=$(sc "$R")
[[ "$SC" == "404" ]] && ok "Geçersiz bildirim okundu → 404" || warn "Geçersiz bildirim → HTTP $SC (404 beklendi)"

# ============================================================
section "8. ŞİFRE GÜNCELLEME"
# ============================================================

# 8.1 Şifre güncelle
R=$(req PATCH "$BASE/api/kullanici/$SAKIN_ID/sifre" \
  '{"eskiSifre":"Test123!","yeniSifre":"NewPass456!"}' "$SAKIN_TOKEN")
SC=$(sc "$R")
[[ "$SC" == "200" ]] && ok "Şifre güncelle → 200" || fail "Şifre güncelle → HTTP $SC | $(body "$R" | head -c 150)"

# 8.2 Yeni şifre ile giriş
R=$(req POST "$BASE/api/auth/login" '{"email":"sakin@apartman.com","sifre":"NewPass456!"}')
SC=$(sc "$R")
NEW_SAKIN_TOKEN=$(get_token "$R")
if [[ "$SC" == "200" && -n "$NEW_SAKIN_TOKEN" ]]; then
  ok "Yeni şifre ile giriş doğrulandı → 200"
  SAKIN_TOKEN="$NEW_SAKIN_TOKEN"
else
  fail "Yeni şifre ile giriş → HTTP $SC (şifre güncelleme başarısız)"
fi

# 8.3 Yanlış eski şifre → 400
R=$(req PATCH "$BASE/api/kullanici/$SAKIN_ID/sifre" \
  '{"eskiSifre":"YanlisEski","yeniSifre":"Test999!"}' "$SAKIN_TOKEN")
SC=$(sc "$R")
[[ "$SC" == "400" ]] && ok "Yanlış eski şifre → 400" || warn "Yanlış eski şifre → HTTP $SC (400 beklendi)"

# 8.4 Başka kullanıcının şifresini değiştirmeye çalış → 403
R=$(req PATCH "$BASE/api/kullanici/$ADMIN_ID/sifre" \
  '{"eskiSifre":"Test123!","yeniSifre":"Hacked!"}' "$SAKIN_TOKEN")
SC=$(sc "$R")
[[ "$SC" == "403" ]] && ok "Başka kullanıcı şifre değiştirme → 403" || fail "Başka şifre → HTTP $SC (403 beklendi)"

# Şifreyi geri al
req PATCH "$BASE/api/kullanici/$SAKIN_ID/sifre" \
  '{"eskiSifre":"NewPass456!","yeniSifre":"Test123!"}' "$SAKIN_TOKEN" > /dev/null 2>&1

# ============================================================
section "9. TEMİZLİK"
# ============================================================

do_delete() {
  local url=$1 token=$2 label=$3
  R=$(req DELETE "$url" "" "$token")
  SC=$(sc "$R")
  [[ "$SC" == "200" ]] && ok "$label sil → 200" || warn "$label sil → HTTP $SC"
}

[[ -n "$ARIZA_ID"      ]] && do_delete "$BASE/api/ariza/$ARIZA_ID"          "$ADMIN_TOKEN" "Arıza #$ARIZA_ID"
[[ -n "$ARIZA_ID2"     ]] && do_delete "$BASE/api/ariza/$ARIZA_ID2"         "$ADMIN_TOKEN" "Arıza #$ARIZA_ID2"
[[ -n "$TAKIP_ARIZA_ID" ]] && do_delete "$BASE/api/ariza/$TAKIP_ARIZA_ID"   "$ADMIN_TOKEN" "Takip arızası"
[[ -n "$AIDAT_ID"      ]] && do_delete "$BASE/api/aidat/$AIDAT_ID"          "$ADMIN_TOKEN" "Aidat #$AIDAT_ID"
[[ -n "$OA_ID"         ]] && do_delete "$BASE/api/otomatik-aidat/$OA_ID"   "$ADMIN_TOKEN" "Otomatik aidat #$OA_ID"
[[ -n "$NEW_USER_ID"   ]] && do_delete "$BASE/api/kullanici/$NEW_USER_ID"   "$ADMIN_TOKEN" "Test kullanıcısı #$NEW_USER_ID"

# ============================================================
echo ""
echo -e "${CBOLD}══════════════════════════════════════════${CNC}"
TOTAL=$((PASS + FAIL + WARN))
echo -e "${CBOLD}  SONUÇ:  ${CGREEN}$PASS PASS${CNC}  |  ${CRED}$FAIL FAIL${CNC}  |  ${CYELLOW}$WARN WARN${CNC}  |  Toplam: $TOTAL${CNC}"
echo -e "${CBOLD}══════════════════════════════════════════${CNC}"
if [[ $FAIL -eq 0 && $WARN -eq 0 ]]; then
  echo -e "  ${CGREEN}${CBOLD}Tüm testler başarıyla geçti!${CNC}"
elif [[ $FAIL -eq 0 ]]; then
  echo -e "  ${CYELLOW}${CBOLD}$WARN uyarı var, kritik hata yok.${CNC}"
else
  echo -e "  ${CRED}${CBOLD}$FAIL kritik hata, $WARN uyarı.${CNC}"
fi
echo ""
