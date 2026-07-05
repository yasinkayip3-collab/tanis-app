# 🤝 Tanış App

Arkadaşlık ve tanışma uygulaması - Flutter + Supabase

---

## 🚀 Kurulum (Adım Adım)

### 1. Supabase Hesabı Aç
1. https://supabase.com adresine git
2. "Start your project" ile ücretsiz hesap aç
3. Yeni proje oluştur (isim: `tanis-app`)
4. Proje oluşunca **Settings > API** sayfasını aç
5. Şunları kopyala:
   - `Project URL` → `https://xxxxx.supabase.co`
   - `anon public` key

### 2. Veritabanını Kur
1. Supabase > **SQL Editor** > New query
2. `supabase/schema.sql` dosyasının tüm içeriğini yapıştır
3. **Run** butonuna bas
4. "Success" yazısını gör ✅

### 3. SMS Doğrulamayı Aç
1. Supabase > **Authentication > Providers**
2. **Phone** provider'ı aç
3. Twilio hesabı aç (https://twilio.com) - ücretsiz deneme kredisi var
4. Twilio'dan Account SID, Auth Token, Phone Number al
5. Bunları Supabase Phone settings'e yapıştır

### 4. Flutter Kurulumu
```bash
# Flutter yükle (eğer yoksa)
# https://flutter.dev/docs/get-started/install

# Projeyi klonla / klasörü aç
cd tanis_app

# Bağımlılıkları yükle
flutter pub get

# lib/main.dart dosyasını aç ve şunu düzenle:
# url: 'https://PROJE_ID.supabase.co'  ← kendi URL'ini yaz
# anonKey: 'ANON_KEY_BURAYA'           ← kendi key'ini yaz
```

### 5. Çalıştır
```bash
# Telefonu USB ile bağla veya emülatör aç
flutter run
```

---

## 📁 Proje Yapısı

```
lib/
  main.dart                  ← Giriş noktası + tema
  screens/
    splash_screen.dart       ← Yükleme ekranı
    auth_screen.dart         ← SMS doğrulama
    profile_setup_screen.dart← 4 adımlı profil kurulumu
    home_screen.dart         ← Ana sayfa (tab bar)
  services/
    supabase_service.dart    ← Tüm Supabase işlemleri
supabase/
  schema.sql                 ← Veritabanı tabloları
```

---

## 🔜 Sıradaki Adımlar

- [ ] Swipe kartları (keşfet ekranı)
- [ ] Gerçek zamanlı mesajlaşma
- [ ] Profil düzenleme
- [ ] Bildirimler (push notification)
